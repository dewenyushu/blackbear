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
[]

[UserObjects]
  [neml2_stress_UO]
    type = CauchyStressFromNEML2UO
    temperature = 'T'
    model = 'elasticity_model'
    parameter_derivatives = "E"
  []
[]

[AuxVariables]
  [T]
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
  [bottom_x]
    type = DirichletBC
    variable = ux
    boundary = bottom
    value = 0.0
  []
  [bottom_y]
    type = DirichletBC
    variable = uy
    boundary = bottom
    value = 0.0
  []
  [top_x]
    type = NeumannBC
    variable = ux
    boundary = top
    value = 1.0
  []
  [top_y]
    type = NeumannBC
    variable = uy
    boundary = top
    value = 1.0
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

[Reporters]
  [measure_data]
    type = OptimizationData
    variable = ux
  []
  [parametrization]
    type = ConstantReporter
    real_vector_names = 'coordx coordy lambda mu'
    real_vector_values = '0 1 2; 0 1 2; 5 4 3; 1 2 3'
  []
[]

[Postprocessors]
  [point1]
    type = PointValue
    point = '-1.0 -1.0 0.0'
    variable = ux
    execute_on = TIMESTEP_END
  []
  [point2]
    type = PointValue
    point = '-1.0 0.0 0.0'
    variable = ux
    execute_on = TIMESTEP_END
  []
  [point3]
    type = PointValue
    point = '-1.0 1.0 0.0'
    variable = ux
    execute_on = TIMESTEP_END
  []

  [cauchy_stress_xx]
    type = ElementAverageMaterialProperty
    mat_prop = cauchy_stress_xx
  []
[]

[Outputs]
  file_base = 'fem'
  exodus = true
  csv = true
[]
