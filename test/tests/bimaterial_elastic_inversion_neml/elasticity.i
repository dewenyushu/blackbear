[Tensors]
  [E]
    type = FullScalar
    batch_shape = '(484)'
    value = 3
  []
[]

[Models]
  [elasticity_model]
    type = LinearIsotropicElasticity
    youngs_modulus = E
    poisson_ratio = 0.25
    strain = 'forces/E'
  []
[]
