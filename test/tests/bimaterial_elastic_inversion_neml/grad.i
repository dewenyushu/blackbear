[GlobalParams]
  displacements = 'ux uy'
[]

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 11
    ny = 11
    xmin = -4
    xmax = 4
    ymin = -4
    ymax = 4
  []
[]

[AuxVariables]
  [state_x]
  []
  [state_y]
  []
  [dummy]
  []
  [T]
  []
[]

[DiracKernels]
  [misfit_is_adjoint_force]
    type = ReporterPointSource
    variable = ux
    x_coord_name = misfit/measurement_xcoord
    y_coord_name = misfit/measurement_ycoord
    z_coord_name = misfit/measurement_zcoord
    value_name = misfit/misfit_values
  []
[]

[Modules]
  [TensorMechanics]
    [Master]
      [all]
        strain = SMALL
        new_system = true
        add_variables = true
        formulation = TOTAL
        incremental = true
        volumetric_locking_correction = false
        generate_output = 'cauchy_stress_xx'
      []
    []
  []
[]

[BCs]
  [BCs]
    [bottom_ux]
      type = DirichletBC
      variable = ux
      boundary = bottom
      value = 0.0
    []
    [bottom_uy]
      type = DirichletBC
      variable = uy
      boundary = bottom
      value = 0.0
    []
  []
[]

[NEML2]
  input = 'elasticity.i'
  model = 'elasticity_model'
  temperature = 'T'
  verbose = true
  # mode = ALL
  mode = PARSE_ONLY
  device = 'cpu'
  # parameter_derivatives = "E"
[]

[Materials]
  [stress]
    type = CauchyStressFromNEML2Receiver
    neml2_uo = neml2_stress_UO
  []
  # [elasticity_tensor]
  #   type = ComputeVariableIsotropicElasticityTensor
  #   args = dummy
  #   youngs_modulus = E_material
  #   poissons_ratio = 0.25
  # []
  [E_material]
    type = GenericFunctionMaterial
    prop_names = 'E_material'
    prop_values = E
  []
  [forward_strain]
    type = ComputeSmallStrain
    displacements = 'state_x state_y'
    base_name = 'forward'
  []
[]

[Functions]
  [E]
    type = NearestReporterCoordinatesFunction
    x_coord_name = parametrization/coordx
    y_coord_name = parametrization/coordy
    value_name = parametrization/youngs_modulus
  []
[]

[Reporters]
  [parametrization]
    type = ConstantReporter
    real_vector_names = 'coordx coordy youngs_modulus'
    real_vector_values = '0 1 2; 0 1 2; 5 4 3'
  []
[]

[UserObjects]
  [neml2_stress_UO]
    type = CauchyStressFromNEML2UO
    temperature = 'T'
    model = 'elasticity_model'
    parameter_derivatives = "E"
  []
[]

[VectorPostprocessors]
  [grad_E]
    type = AdjointStrainStressGradNEML2InnerProduct
    neml2_uo = neml2_stress_UO
    adjoint_strain_name = 'mechanical_strain'
    variable = dummy
    function = E
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  # required for NEML2 material models
  residual_and_jacobian_together = true
[]

[Outputs]
  file_base = 'adjoint'
  console = false
[]
