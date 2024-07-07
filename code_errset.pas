{   Routines to fill in STAT for various errors.
}
module code_errset;
define code_errset_sym_exist;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_ERRSET_SYM_EXIST (POS, STAT)
*
*   Fill in STAT to indicate symbol previously exists error.  POS is the symbol
*   table position of the existing symbol.
}
procedure code_errset_sym_exist (      {fill in STAT for symbol already exists}
  in      pos: string_hash_pos_t;      {symbol table position for existing symbol}
  out     stat: sys_err_t);            {filled in with appropriate error status}
  val_param;

var
  name_p: string_var_p_t;              {to existing symbol name in symbol table}
  sym_p: code_symbol_p_t;              {to previously existing symbol}

begin
  string_hash_ent_atpos (pos, name_p, sym_p); {get info on the existing symbol}

  sys_stat_set (code_subsys_k, code_stat_sym_exist_k, stat); {set error code}
  sys_stat_parm_vstr (name_p^, stat);  {add symbol name}
  fline_stat_lnum_fnam (stat, sym_p^.pos); {add line number and file name}
  end;
