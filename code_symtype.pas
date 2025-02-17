{   Symbol type IDs and their associated names.
}
module code_symtype;
define code_symtype_t_name;
define code_symtype_f_name;
%include 'code2.ins.pas';

const
  maxnlen = 7;                         {max length of any symbol type name}

type
  tyname_t = array[1..maxnlen] of char; {string to hold one name with trailing blank}

var
  {
  *   WARNING: The symbol type names in this TYNAMES table must exactly follow
  *   the order of the ordinal values of the symbol type IDs CODE_SYMTYPE_K_T
  *   defined in CODE.INS.PAS.
  *
  *   Although the symbol type names are case-insensitive, they must be stored
  *   here in upper case.
  }
  tynames:                             {table of symbol type names}
       array[firstof(code_symtype_k_t)..lastof(code_symtype_k_t)]
       of tyname_t := [
    'INVALID',
    'UNKNOWN',
    'UNDEF  ',
    'SCOPE  ',
    'MEMORY ',
    'MEMREG ',
    'ADRSP  ',
    'ADRREG ',
    'CONST  ',
    'ENUM   ',
    'DTYPE  ',
    'FIELD  ',
    'VAR    ',
    'ALIAS  ',
    'PROC   ',
    'PROG   ',
    'COMBLK ',
    'MODULE ',
    'LABEL  ',
    ];
{
********************************************************************************
*
*   Subroutine CODE_SYMTYPE_T_NAME (SYMTYPE, NAME)
*
*   Get the text name for a symbol type.  SYMTYPE is the symbol type ID, and
*   NAME is returned its text name in upper case.
}
procedure code_symtype_t_name (        {get symbol type name from symbol type ID}
  in      symtype: code_symtype_k_t;   {symbol type ID}
  in out  name: univ string_var_arg_t); {returned symbol type name}
  val_param;

begin
  string_vstring (name, tynames[symtype], maxnlen); {get name from table, unpad}
  end;
{
********************************************************************************
*
*   Function CODE_SYMTYPE_F_NAME (TYNAME)
*
*   Return the symbol type ID for the symbol type name TYNAME.  The special type
*   ID of CODDE_SYMTYPE_INVALID_K is returned when TYNAME is not a valid symbol
*   type name.  TYNAME is case-insensitive.
}
function code_symtype_f_name (         {get the symbol type from the type name}
  in      tyname: univ string_var_arg_t) {symbol type name, case-insensitive}
  :code_symtype_k_t;                   {symbol type ID, INVALID when unrecognized}
  val_param;

var
  ty: code_symtype_k_t;                {current type ID checking name for}
  nameu: string_var32_t;               {upper case version of TYNAME}
  tblnam: string_var32_t;              {name from table for current ID}

begin
  nameu.max := size_char(nameu.str);   {init local var strings}
  tblnam.max := size_char(tblnam.str);

  string_copy (tyname, nameu);         {make upper case symbol type name}
  string_upcase (nameu);

  for ty := firstof(code_symtype_k_t) to lastof(code_symtype_k_t) do begin
    string_vstring (tblnam, tynames[ty], maxnlen); {get name in this table entry}
    if string_equal (tblnam, nameu) then begin {found match ?}
      code_symtype_f_name := ty;       {return type ID for this table entry}
      return;
      end;
    end;                               {back to try next table entry}

  code_symtype_f_name := code_symtype_invalid_k; {indicate invalid type name}
  end;
