Map Pattern:
  based on: strictyaml
  description: |
    When you do not wish to let the user define the key
    names in a mapping and and only specify what type the
    keys are, use a MapPattern.

    When you wish to specify the exact key name, use the
    'Map' validator instead.
  preconditions:
    files:
      valid_sequence_1.yaml: |
        â: 1
        b: 2
      valid_sequence_2.yaml: |
        a: 1
        c: 3
      valid_sequence_3.yaml: |
        a: 1
      invalid_sequence_1.yaml: |
        b: b
      invalid_sequence_2.yaml: |
        a: a
        b: 2
      invalid_sequence_3.yaml: |
        a: 1
        b: yâs
        c: 3
  scenario:
    - Run command: |
        from strictyaml import MapPattern, Int, Str, YAMLValidationError, load

        schema = MapPattern(Str(), Int())

    - Assert True: 'load(valid_sequence_1, schema) == {u"â": 1, "b": 2}'

    - Assert True: 'load(valid_sequence_2, schema) == {"a": 1, "c": 3}'

    - Assert True: 'load(valid_sequence_3, schema) == {"a": 1, }'

    - Assert Exception:
        command: load(invalid_sequence_1, schema)
        exception: |
          when expecting an integer
          found non-integer
            in "<unicode string>", line 1, column 1:
              b: b
               ^

    - Assert Exception:
        command: load(invalid_sequence_2, schema)
        exception: |
          when expecting an integer
          found non-integer
            in "<unicode string>", line 1, column 1:
              a: a
               ^

    - Assert Exception:
        command: load(invalid_sequence_3, schema)
        exception: |
          when expecting an integer
          found non-integer
            in "<unicode string>", line 2, column 1:
              b: "y\xE2s"
              ^
