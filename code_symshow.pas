{   Routines related to showing tree structure of symbols.
}
module code_symshow;
define code_symshow_init;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SYMSHOW_INIT (SYMSHOW)
*
*   Initialize the control state for showing a tree of symbols.  The control
*   state is initialized to the following options:
*
*     Only one level is show.  Subordinate name spaces are not expanded.
*
*     No comments associated with the symbol are shown.
*
*     The source code location is not shown.
*
*     Subordinate symbols (such as fields in an aggregate data type) are shown
*     but not expanded.
*
*   The nesting state is initialized to the top level symbol of the original
*   call.
*
*   Applications should call this routine to initialize a CODE_SYMSHOW_T
*   structure before each use.  Instance specific modifications are then made
*   after this call.  This procedure guarantees that internal state used in
*   traversing the tree of symbols to show is properly initialized.  It also
*   protects applications from new features being added.  Those features will
*   default to off so that old applications will continue to run as before.
}
procedure code_symshow_init (          {init control state for showing symbols tree}
  out     symshow: code_symshow_t);    {will be set to default state}
  val_param;

begin
  symshow.opt := [code_symshow_sub_k]; {show private subordinate symbols}
  symshow.maxlev := 1;                 {show only level of original call}
  symshow.lev := 0;                    {init internal state for traversing tree}
  end;
