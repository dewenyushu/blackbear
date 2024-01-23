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

#pragma once

#include "CauchyStressFromNEML2UO.h"
// #include "ComputeLagrangianObjectiveStress.h"
#include "ElementOptimizationFunctionInnerProduct.h"

/**
 * This is a "glue" material that retrieves the batched output vector from a NEML2 material model
 * and uses the output variables to perform the objective stress integration.
 */
class AdjointStrainStressGradNEML2InnerProduct : public ElementOptimizationFunctionInnerProduct
{
public:
  static InputParameters validParams();
  AdjointStrainStressGradNEML2InnerProduct(const InputParameters & parameters);

protected:
  virtual Real computeQpInnerProduct() override;

   /// Base name of the material system
  const std::string _base_name;
  /// Holds adjoint strain at current quadrature points
  const MaterialProperty<RankTwoTensor> & _adjoint_strain;

  /// The NEML2 userobject that actually performs the batched computation
  const CauchyStressFromNEML2UO & _neml2_uo;

  /// The output from the NEML2 userobject
  const CauchyStressFromNEML2UO::OutputVector & _output;
};
