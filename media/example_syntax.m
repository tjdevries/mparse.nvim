  ;
ExampleRoutine ;
  q
  ; SCOPE: PUBLIC
  ; DESCRIPTION: This is an exammple
  ; Check this out...
Example(var) ;;#compDirective# It can handle compiler directives
  n factor
  s factor("NOT A THING")=$$setDefault(0,factor("NOT A THING"),"default")
  s factor("NOT A THING")=$G(factor("NOT A THING"),$s(1:$$writeSomeStuff("hopefully this doesn't print twice")))
  n myVar
  s myVar=$G(myVar,$s(1:$$writeSomeStuff("this out to print once and then again")))
  s indirected=@$$exampleFunc("a",.dotVar)@("index")
  q
