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

#ifdef NEML2_ENABLED
#include "neml2/models/Model.h"
#endif

#include "Action.h"

/**
 * Action to parse and set up NEML2 objects.
 */
class NEML2Action : public Action
{
public:
  static InputParameters validParams();

  NEML2Action(const InputParameters & params);

  virtual void act() override;

#ifdef NEML2_ENABLED
protected:
  /// Name of the NEML2 input file
  FileName _fname;

  /// Name of the NEML2 material model to import from the NEML2 input file
  std::string _mname;

  /// Whether to print additional information about the NEML2 mateiral model
  const bool _verbose;

  const std::vector<std::string> & _parameter_derivatives;

  /// Whether to require derivatives of output with respect to model parameters

  const bool _require_parameter_derivatives;

  /// The operation mode
  const MooseEnum _mode;

  /// The device on which to evaluate the NEML2 model
  const torch::Device _device;
#endif
};
