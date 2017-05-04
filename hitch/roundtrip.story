Roundtripped YAML:
  based on: strictyaml
  description: |
    Loaded YAML can be dumped out again and commments
    should be preserved.

    Loaded YAML can even be modified and dumped out again too.
  preconditions:
    files:
      commented_yaml.yaml: |
        # Some comment
        
        a: â # value comment
        
        # Another comment
        b: y
      modified_commented_yaml.yaml: |
        # Some comment
        
        a: â # value comment
        
        # Another comment
        b: x
      with_integer: |
        x: 1
  scenario:
    - Run command: |
        from strictyaml import Map, Str, Int, YAMLValidationError, load

        schema = Map({"a": Str(), "b": Str()})

    - Assert True: |
        load(commented_yaml, schema).as_yaml() == commented_yaml

    - Run command: |
        to_modify = load(commented_yaml, schema)

        to_modify['b'] = 'x'

    - Assert True: |
        to_modify.as_yaml() == modified_commented_yaml

    #- Run command: |
        #from ruamel.yaml import load, dump, RoundTripLoader, RoundTripDumper
    
    #- Run command: |
        #xxx = load("x: 1", Loader=RoundTripLoader)

    - Assert True: |
       load(with_integer, Map({"x": Int()})).as_yaml() == "x: 1\n"
