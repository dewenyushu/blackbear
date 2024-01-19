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
  [state_x]
  []
  [state_y]
  []
  [dummy]
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
    youngs_modulus = E_material
    poissons_ratio = 0.25
  []
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
  [measure_data]
    type = OptimizationData
    variable = ux
  []
  [misfit]
    type = OptimizationData
  []
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
[]

[Outputs]
  file_base = 'adjoint'
  console = false
[]
