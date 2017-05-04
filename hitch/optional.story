Optional validation:
  based on: strictyaml
  preconditions:
    files:
      valid_sequence_1.yaml: |
        a: 1
        b: yes
      valid_sequence_2.yaml: |
        a: 1
        b: no
      valid_sequence_3.yaml: |
        a: 1
      valid_sequence_4.yaml: |
        a: 1
        b:
          x: y
          y: z
      invalid_sequence_1.yaml: |
        b: 2
      invalid_sequence_2.yaml: |
        a: 1
        b: 2
      invalid_sequence_3.yaml: |
        a: 1
        b: yes
        c: 3
  scenario:
    - Run command: |
        from strictyaml import Map, Int, Str, Bool, Optional, YAMLValidationError, load

        schema = Map({"a": Int(), Optional("b"): Bool(), })

    - Assert True: 'load(valid_sequence_1, schema) == {"a": 1, "b": True}'
    - Assert True: 'load(valid_sequence_2, schema) == {"a": 1, "b": False}'
    - Assert True: 'load(valid_sequence_3, schema) == {"a": 1}'

    - Run command: |
        load(valid_sequence_4, Map({"a": Int(), Optional("b"): Map({Optional("x"): Str(), Optional("y"): Str()})}))

    - Assert Exception:
        command: load(invalid_sequence_1, schema)
        exception: |
          when expecting a boolean value (one of "yes", "true", "on", "1", "no", "false", "off", "0")
          found non-boolean
            in "<unicode string>", line 1, column 1:
              b: '2'
               ^

    - Assert Exception:
        command: load(invalid_sequence_2, schema)
        exception: |
          when expecting a boolean value (one of "yes", "true", "on", "1", "no", "false", "off", "0")
          found non-boolean
            in "<unicode string>", line 2, column 1:
              b: '2'
              ^

    - Assert Exception:
        command: load(invalid_sequence_3, schema)
        exception: |
          while parsing a mapping
          unexpected key not in schema 'c'
            in "<unicode string>", line 3, column 1:
              c: '3'
              ^
