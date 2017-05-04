Sequence validation:
  based on: strictyaml
  preconditions:
    files:
      valid_sequence.yaml: |
        - 1
        - 2
        - 3
      invalid_sequence_1.yaml: |
        a: 1
        b: 2
        c: 3
      invalid_sequence_2.yaml: |
        - 2
        - 3
        - a:
          - 1
          - 2
      invalid_sequence_3.yaml: |
        - 1.1
        - 1.2
      invalid_sequence_4.yaml: |
        - 1
        - 2
        - 3.4
  scenario:
    - Run command: |
        from strictyaml import Seq, Str, Int, YAMLValidationError, load

    - Assert True: load(valid_sequence, Seq(Str())) == ["1", "2", "3", ]

    - Assert True: load(valid_sequence, Seq(Str())).is_sequence()

    - Assert Exception:
        command: load(valid_sequence, Seq(Str())).text
        exception: is a sequence, has no text value.

    - Assert Exception:
        command: load(invalid_sequence_1, Seq(Str()))
        exception: |
          when expecting a sequence
            in "<unicode string>", line 1, column 1:
              a: '1'
               ^ (line: 1)
          found non-sequence
            in "<unicode string>", line 3, column 1:
              c: '3'
              ^ (line: 3)

    - Assert Exception:
        command: load(invalid_sequence_2, Seq(Str()))
        exception: |
          when expecting a str
            in "<unicode string>", line 3, column 1:
              - a:
              ^ (line: 3)
          found mapping/sequence
            in "<unicode string>", line 5, column 1:
                - '2'
              ^ (line: 5)


    - Assert Exception:
        command: load(invalid_sequence_3, Seq(Int()))
        exception: |
          when expecting an integer
          found non-integer
            in "<unicode string>", line 1, column 1:
              - '1.1'
               ^ (line: 1)

    - Assert Exception:
        command: load(invalid_sequence_4, Seq(Int()))
        exception: |
          when expecting an integer
          found non-integer
            in "<unicode string>", line 3, column 1:
              - '3.4'
              ^ (line: 3)
