/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/*                       BlackBear                              */
/*                                                              */
/*           (c) 2017 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#include "CauchyStressFromNEML2.h"
#include "NEML2Utils.h"
#include "NonlinearSystem.h"
#include "libmesh/nonlinear_solver.h"

registerMooseObject("BlackBearApp", CauchyStressFromNEML2);

InputParameters
CauchyStressFromNEML2::validParams()
{
  InputParameters params =
      NEML2SolidMechanicsInterface<ComputeLagrangianObjectiveStress>::validParams();
  params.addClassDescription("Perform the objective stress update using a NEML2 material model");
  params.addCoupledVar("temperature", "Coupled temperature");
  return params;
}

#ifdef NEML2_ENABLED

CauchyStressFromNEML2::CauchyStressFromNEML2(const InputParameters & parameters)
  : NEML2SolidMechanicsInterface<ComputeLagrangianObjectiveStress>(parameters),
    // Inputs to the constitutive model
    _mechanical_strain_old(nullptr),
    _temperature(nullptr),
    _temperature_old(nullptr)
{
  validateModel();

  // Get the old mechanical strain if the NEML2 model need it
  _mechanical_strain_old =
      model().input().has_variable(strainOld())
          ? &getMaterialPropertyOld<RankTwoTensor>(_base_name + "mechanical_strain")
          : nullptr;

  // Get the temperature if the NEML2 model need it
  _temperature =
      model().input().has_variable(temperature()) ? &coupledValue("temperature") : nullptr;

  // Get the old temperature if the NEML2 model need it
  _temperature =
      model().input().has_variable(temperatureOld()) ? &coupledValueOld("temperature") : nullptr;

  // Find the stateful state variables.
  // A state variable is said to be stateful if it exists on the input's old_state axis as well as
  // on the output's state axis.
  if (model().input().has_subaxis("old_state"))
    for (auto var : model().input().subaxis("old_state").variable_accessors(/*recursive=*/true))
    {
      _state_vars[var.on("state")] = &declareProperty<std::vector<Real>>(Moose::stringify(var));
      _state_vars_old[var.on("old_state")] =
          &getMaterialPropertyOld<std::vector<Real>>(Moose::stringify(var));
    }
}

void
CauchyStressFromNEML2::initialSetup()
{
  auto solver = _fe_problem.getNonlinearSystem(/*nl_sys_num=*/0).nonlinearSolver();
  if (solver->residual_object || solver->jacobian || !solver->residual_and_jacobian_object)
    mooseWarning("NEML2 material models are designed to be used together with "
                 "residual_and_jacobian_together = true.");
}

void
CauchyStressFromNEML2::initQpStatefulProperties()
{
  ComputeLagrangianObjectiveStress::initQpStatefulProperties();

  // TODO: provide a mechanism to initialize the internal variables to non-zeros
  for (auto && [var, prop] : _state_vars)
    (*prop)[_qp] = std::vector<Real>(model().output().storage_size(var), 0);
}

void
CauchyStressFromNEML2::computeProperties()
{
  try
  {
    // Allocate input
    _in = neml2::LabeledVector::zeros(_qrule->n_points(), {&model().input()});

    advanceStep();

    updateForces();

    if (model().implicit())
      applyPredictor();

    solve();
  }
  catch (neml2::NEMLException & e)
  {
    mooseException("An error occurred during the evaluation of a NEML2 model:\n",
                   e.what(),
                   NEML2Utils::NEML2_help_message);
  }
  catch (std::runtime_error & e)
  {
    mooseException("An unknown error occurred during the evaluation of a NEML2 model:\n",
                   e.what(),
                   "\nIt is possible that this error is related to NEML2.",
                   NEML2Utils::NEML2_help_message);
  }

  ComputeLagrangianObjectiveStress::computeProperties();
}

void
CauchyStressFromNEML2::computeQpSmallStress()
{
  neml2::TorchSize qp = _qp;

  // Set the results into the corresponding MOOSE material properties
  _small_stress[_qp] =
      NEML2Utils::toMOOSE<SymmetricRankTwoTensor>(_out(stress()).batch_index({qp}));

  _small_jacobian[_qp] = RankFourTensor(NEML2Utils::toMOOSE<SymmetricRankFourTensor>(
      _dout_din(stress(), strain()).batch_index({qp})));

  for (auto && [var, prop] : _state_vars)
    (*prop)[_qp] = NEML2Utils::toMOOSE<std::vector<Real>>(_out(var).batch_index({qp}));
}

void
CauchyStressFromNEML2::advanceStep()
{
  // Set old state variables
  for (auto && [var, prop] : _state_vars_old)
    NEML2Utils::setBatched(_in, {var}, prop);

  // Set old forces
  NEML2Utils::setBatched(
      // The input LabeledVector
      _in,
      // NEML2 variable accessors
      {strainOld(), temperatureOld()},
      // Pointer to the batched data
      _mechanical_strain_old,
      _temperature_old);

  // TransientInterface doesn't provide _t_old...
  auto t_old = _t - _dt;
  NEML2Utils::set(
      // The input LabeledVector
      _in,
      // NEML2 variable accessors
      {timeOld()},
      // Pointer to the unbatched data
      model().input().has_variable(timeOld()) ? &t_old : nullptr);
}

void
CauchyStressFromNEML2::updateForces()
{
  NEML2Utils::setBatched(
      // The input LabeledVector
      _in,
      // NEML2 variable accessors
      {strain(), temperature()},
      // Pointer to the batched data
      &_mechanical_strain,
      _temperature);

  NEML2Utils::set(
      // The input LabeledVector
      _in,
      // NEML2 variable accessors
      {time()},
      // Pointer to the unbatched data
      model().input().has_variable(time()) ? &_t : nullptr);
}

void
CauchyStressFromNEML2::applyPredictor()
{
  // Set trial state variables (i.e., initial guesses).
  // Right now we hard-code to use the old state as the trial state.
  // TODO: implement other predictors
  _in.slice("state").fill(_in.slice("old_state"));
}

void
CauchyStressFromNEML2::solve()
{
  // 1. Sync input onto the model's device
  // 2. Evaluate the NEML2 material model
  // 3. Sync output back onto CPU
  auto res = model().value_and_dvalue(_in.to(device()));
  _out = std::get<0>(res).to(torch::kCPU);
  _dout_din = std::get<1>(res).to(torch::kCPU);
}

#else

CauchyStressFromNEML2::CauchyStressFromNEML2(const InputParameters & parameters)
  : NEML2SolidMechanicsInterface<ComputeLagrangianObjectiveStress>(parameters)
{
}

#endif
