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

[Variables]
  [ux]
  []
  [uy]
  []
[]

[AuxVariables]
  [dummy]
  []
[]

[Kernels]
  [div_sigma_x]
    type = StressDivergenceTensors
    variable = ux
    displacements = 'ux uy'
    component = 0
    volumetric_locking_correction = false
  []
  [div_sigma_y]
    type = StressDivergenceTensors
    variable = uy
    displacements = 'ux uy'
    component = 1
    volumetric_locking_correction = false
  []
[]

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
  [top_fx]
    type = NeumannBC
    variable = ux
    boundary = top
    value = 1.0
  []
  [top_fy]
    type = NeumannBC
    variable = uy
    boundary = top
    value = 1.0
  []
[]

[Materials]
  [stress]
    type = ComputeLinearElasticStress
  []
  [strain]
    type = ComputeSmallStrain
    displacements = 'ux uy'
  []
  [elasticity_tensor]
    type = ComputeVariableIsotropicElasticityTensor
    args = dummy
    youngs_modulus = 7.5
    poissons_ratio = 0.25
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
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
[]

[Outputs]
  console = true
  csv = true
[]
