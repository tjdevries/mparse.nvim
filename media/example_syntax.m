ExampleRoutine ; This is a routine
  q
  ; SCOPE:       PUBLIC
  ; DESCRIPTION: This is an exammple
  ; Check this out...
Example(var) ;;#testTag# It can handle compiler directives
  n factor,idx,myVar
  ; It knows about intrinsics!
  s factor($J)=$$setDefault(0,factor,"default")
  s ^GLOBAL="Test"
  ;
  ; Handles intrinsic functions and user functions
  s factor("Some Index")=$G(factor("NOT A THING"),$s(1:$$writeSomeStuff("hopefully this doesn't print twice")))
  ;
  f  s idx=$$nextID(idx) q:idx=""  d  q:(idx="DONE")!(idx="FINISH")
  . w !,"This is a for loop"
  ;
  s myVar=$G(myVar,$s(1:$$writeSomeStuff("this out to print once and then again")))
  s indir=@myVar@("hello","world")=10
  s indirected=@$$exampleFunc("a",.dotVar)@("index")
  q
