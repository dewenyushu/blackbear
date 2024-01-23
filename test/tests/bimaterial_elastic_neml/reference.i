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
    base_name = forward
  []
  [div_sigma_y]
    type = StressDivergenceTensors
    variable = uy
    displacements = 'ux uy'
    component = 1
    volumetric_locking_correction = false
    base_name = forward
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
    base_name = forward
  []
  [strain]
    type = ComputeSmallStrain
    displacements = 'ux uy'
    base_name = forward
  []
  [elasticity_tensor]
    type = ComputeVariableIsotropicElasticityTensor
    args = dummy
    youngs_modulus = 7.5
    poissons_ratio = 0.25
    base_name = forward
  []
  # Below are the gradients of elasticity tensor for this elastic inversion problem
  [dC_dE]
    type = ComputeElasticityTensor
    C_ijkl = '1.2 0.4 0.4 1.2 0.4 1.2 0.4 0.4 0.4'
    fill_method = symmetric9
    base_name = 'dC_dE'
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

# Below is the part where a customized userObject that takes NEML stress gradient
# and transforms it into a batch material that has the output type as RankTwoTensor
# One userObject per gradient material property from NEML
[UserObjects]
  [stress_grad_E]
    type = BatchStressGrad
    elasticity_tensor_derivative = 'dC_dE_elasticity_tensor' # calculated in dC_dlambda
  []
[]

# Below is where the stress gradient batch material objects are utilized in the
# actual gradient calculations
[VectorPostprocessors]
  [grad_youngs_modulus]
    type = AdjointStrainStressGradInnerProduct
    stress_grad_name = 'stress_grad_E'
    adjoint_strain_name = 'forward_mechanical_strain'
    variable = dummy
    function = E
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
