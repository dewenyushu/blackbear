//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "BatchScalarProperty.h"
#include "libmesh/int_range.h"

registerMooseObject("BlackBearApp", BatchScalarProperty);

InputParameters
BatchScalarProperty::validParams()
{
  auto params = BatchScalarPropertyParent::validParams();
  params.addRequiredParam<MaterialPropertyName>("material_property",
                                                "Name of the scalar material property.");
  params.setDocString("execution_order_group",
                      "BatchScalarProperty userObject needs to be completely executed before "
                      "vectorPostprocessors.");

  params.set<int>("execution_order_group") = -1;

  // keep consistent with CauchyStressFromNEML2UO
  ExecFlagEnum execute_options = MooseUtils::getDefaultExecFlagEnum();
  execute_options = {EXEC_INITIAL, EXEC_LINEAR};
  params.set<ExecFlagEnum>("execute_on") = execute_options;

  params.addClassDescription("Convert scalar material property to BatchMaterial.");
  return params;
}

BatchScalarProperty::BatchScalarProperty(const InputParameters & params)
  : BatchScalarPropertyParent(
        params,
        // here we pass the material property that we are trying to convert to BatchMaterial
        "material_property")
{
}

void
BatchScalarProperty::batchCompute()
{
  for (const auto i : index_range(_input_data))
  {
    _output_data[i] = std::get<0>(_input_data[i]);
  }
}
