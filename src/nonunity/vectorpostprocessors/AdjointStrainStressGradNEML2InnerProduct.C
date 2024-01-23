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

#include "AdjointStrainStressGradNEML2InnerProduct.h"

#include "NEML2Utils.h"

registerMooseObject("BlackBearApp", AdjointStrainStressGradNEML2InnerProduct);

InputParameters
AdjointStrainStressGradNEML2InnerProduct::validParams()
{
  InputParameters params = ElementOptimizationFunctionInnerProduct::validParams();
  params.addClassDescription(
      "Retrieve the batched output vector from a NEML2 material model and use the output variables "
      "to perform the objective stress integration");
  params.addRequiredParam<UserObjectName>(
      "neml2_uo", "The NEML2 user object that performs the batched computation");
  params.addRequiredParam<MaterialPropertyName>(
      "adjoint_strain_name", "Name of the strain property in the adjoint problem");
  return params;
}

AdjointStrainStressGradNEML2InnerProduct::AdjointStrainStressGradNEML2InnerProduct(
    const InputParameters & parameters)
  : ElementOptimizationFunctionInnerProduct(parameters),
    _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
    _adjoint_strain(getMaterialPropertyByName<RankTwoTensor>(
        getParam<MaterialPropertyName>("adjoint_strain_name"))),
    _neml2_uo(getUserObject<CauchyStressFromNEML2UO>("neml2_uo")),
    _output(_neml2_uo.getOutputData())
{
  NEML2Utils::requireNEML2(*this);
}

Real
AdjointStrainStressGradNEML2InnerProduct::computeQpInnerProduct()
{
  if (!_neml2_uo.outputReady())
    mooseError("Stress gradient batch material property is not ready to output.");

  const auto index = _neml2_uo.getIndex(_current_elem->id());
  return -_adjoint_strain[_qp].doubleContraction(std::get<2>(_output[index + _qp]));
}
