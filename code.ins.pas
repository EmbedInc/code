{   Public include file for the CODE library.  This library maintains in-memory
*   descriptions of executable code.  These descriptions are independent of any
*   particular computer language.
}
const
  code_subsys_k = -72;                 {Embed subsystem ID for the CODE library}
  code_align_natural_k = -1;           {special ID for natural alignment}
  {
  *   Error status codes.  There is a ERRn message in the CODE.MSG for each of
  *   these.
  }
  code_stat_memsym_exist_k = 1;        {named memory already exists}
  code_stat_nomem_k = 2;               {no such named memory}
  code_stat_notmem_k = 3;              {name is not for a memory}
  code_stat_nomemreg_k = 4;            {no such named memory region}
  code_stat_notmemreg_k = 5;           {name is not for a memory region}
  code_stat_noadrsp_k = 6;             {no such named address space}
  code_stat_notadrsp_k = 7;            {name is not for a address space}
  code_stat_noadrreg_k = 8;            {no such named address region}
  code_stat_notadrreg_k = 9;           {name is not for a address region}
  code_stat_mreg_inlist_k = 10;        {memory region is already in the list}
  code_stat_sym_exist_k = 11;          {symbol already exists}

type
  code_adrregion_p_t = ^code_adrregion_t;
  code_adrspace_p_t = ^code_adrspace_t;
  code_call_arg_p_t = ^code_call_arg_t;
  code_case_p_t = ^code_case_t;
  code_caseval_p_t = ^code_caseval_t;
  code_comm_p_t = ^code_comm_t;
  code_comm_pp_t = ^code_comm_p_t;
  code_dtype_p_t = ^code_dtype_t;
  code_dumarg_p_t = ^code_dumarg_t;
  code_ele_p_t = ^code_ele_t;
  code_exp_p_t = ^code_exp_t;
  code_explist_p_t = ^code_explist_t;
  code_iter_p_t = ^code_iter_t;
  code_memory_p_t = ^code_memory_t;
  code_memreg_ent_p_t = ^code_memreg_ent_t;
  code_memregion_p_t = ^code_memregion_t;
  code_proc_arg_p_t = ^code_proc_arg_t;
  code_proc_p_t = ^code_proc_t;
  code_refmod_p_t = ^code_refmod_t;
  code_scope_p_t = ^code_scope_t;
  code_syent_p_t = ^code_syent_t;
  code_symlist_p_t = ^code_symlist_t;
  code_symlist_ent_p_t = ^code_symlist_ent_t;
  code_sym_field_p_t = ^code_sym_field_t;
  code_sym_proc_p_t = ^code_sym_proc_t;
  code_sym_var_p_t = ^code_sym_var_t;
  code_symbol_p_t = ^code_symbol_t;
  code_symref_p_t = ^code_symref_t;
  code_val_set_p_t = ^code_val_set_t;
  code_value_p_t = ^code_value_t;
  code_symtab_p_t = ^code_symtab_t;
{
*   Comments.  These are in a tree structured hierarchy.
}
  code_commty_k_t = (                  {types of comments}
    code_commty_block_k,               {block of comment lines}
    code_commty_eol_k);                {end of line comment}

  code_comm_t = record                 {one comment}
    prev_p: code_comm_p_t;             {previous block comments also applying here}
    lnum: sys_int_machine_t;           {sequential source line number of last line}
    pos: fline_cpos_t;                 {start position of comment in source files}
    commty: code_commty_k_t;           {comment type}
    case code_commty_k_t of
code_commty_block_k: (                 {block of comment lines}
      block_level: sys_int_machine_t;  {nesting level, top = 0}
      block_list_p: string_fwlist_p_t; {points to list of comment text lines}
      block_last_p: string_fwlist_p_t; {points to last comment line in list}
      block_keep: boolean;             {keep in previous list of this level}
      );
code_commty_eol_k: (                   {end of line comment}
      eol_prev_p: code_comm_p_t;       {to previous end of line comment}
      eol_str_p: string_var_p_t;       {the comment text string}
      eol_used: boolean;               {this EOL comment has been applied}
      );
    end;
{
*   Memories and address spaces.  Memories are where data is stored.  Address
*   spaces are how the processor accesses that data.
}
  code_memaccs_k_t = (                 {types of access to a memory or address space}
    code_memaccs_rd_k,                 {read}
    code_memaccs_wr_k,                 {write}
    code_memaccs_ex_k);                {execute}
  code_memaccs_t = set of code_memaccs_k_t;

  code_memattr_k_t = (                 {memory or address space attributes}
    code_memattr_nv_k);                {memory is non-volatile}
  code_memattr_t = set of code_memattr_k_t;

  code_memory_t = record               {one physical memory connected to the processor}
    sym_p: code_symbol_p_t;            {points to symbol data in symbol table}
    region_p: code_memregion_p_t;      {points to list of regions within this memory}
    bitsadr: sys_int_machine_t;        {number of bits in address}
    bitsdat: sys_int_machine_t;        {number of bits per addressable word}
    accs: code_memaccs_t;              {types of access to this memory}
    attr: code_memattr_t;              {additional attibute flags}
    end;

  code_memregion_t = record            {region within a memory}
    next_p: code_memregion_p_t;        {to next region in the same memory}
    sym_p: code_symbol_p_t;            {points to symbol data in symbol table}
    mem_p: code_memory_p_t;            {memory this region is within}
    adrst: sys_int_conv32_t;           {start address of this region within the memory}
    adren: sys_int_conv32_t;           {end address of this region within the memory}
    accs: code_memaccs_t;              {types of access to this memory}
    end;

  code_memreg_ent_t = record           {one entry in list of memory regions}
    next_p: code_memreg_ent_p_t;       {to next list entry}
    region_p: code_memregion_p_t;      {points to the mem region for this list entry}
    end;

  code_adrspace_t = record             {address space visible to the processor}
    sym_p: code_symbol_p_t;            {points to symbol data in symbol table}
    region_p: code_adrregion_p_t;      {points to list of regions within this adr space}
    bitsadr: sys_int_machine_t;        {number of bits in address}
    bitsdat: sys_int_machine_t;        {number of bits per addressable word}
    accs: code_memaccs_t;              {types of access to this memory}
    end;

  code_adrregion_t = record            {region of address space with consistant attributes}
    next_p: code_adrregion_p_t;        {to next region within same address space}
    sym_p: code_symbol_p_t;            {points to symbol data in symbol table}
    space_p: code_adrspace_p_t;        {address space this region is within}
    adrst: sys_int_conv32_t;           {start address of this region within adr space}
    adren: sys_int_conv32_t;           {end address of this region within adr space}
    memreg_p: code_memreg_ent_p_t;     {list of mem regions mapped to this adr region}
    accs: code_memaccs_t;              {types of access to this memory}
    end;
{
*   Data types.
}
  code_typid_k_t = (                   {all the different data types}
    code_typid_undef_k,                {data type was referenced, but not defined yet}
    code_typid_undefp_k,               {data type is a pointer, but not defined yet}
    code_typid_copy_k,                 {exact copy of another data type}
    code_typid_int_k,                  {integer}
    code_typid_enum_k,                 {enumerated (names for each value)}
    code_typid_float_k,                {floating point}
    code_typid_bool_k,                 {TRUE/FALSE (Boolean)}
    code_typid_char_k,                 {character}
    code_typid_agg_k,                  {aggregate}
    code_typid_array_k,                {array}
    code_typid_set_k,                  {set of an enumerated type}
    code_typid_range_k,                {subrange of a simple data type}
    code_typid_proc_k,                 {pointer to a procedure}
    code_typid_pnt_k,                  {pointer to data}
    code_typid_vstr_k,                 {string with curr len and max len stored}
    code_typid_flxstr_k);              {string with extendable length}

  code_typflag_k_t = (                 {flags for data types}
    code_typflag_pack_k);              {pack to min bits}
  code_typflag_t = set of code_typflag_k_t;

  code_dtype_t = record                {definition of a data type}
    symbol_p: code_symbol_p_t;         {points to symbol representing this data type}
    comm_p: code_comm_p_t;             {related comments}
    bits_min: sys_int_machine_t;       {minimum required bits}
    mem_p: code_memory_p_t;            {to memory this data structure in, if specific}
    flags: code_typflag_t;             {set of individual option flags}
    typ: code_typid_k_t;               {data type ID, use CODE_TYPID_xxx_K}
    case code_typid_k_t of             {different data for each type}
code_typid_undef_k: (                  {undefined}
      );
code_typid_undefp_k: (                 {undefined pointer}
      );
code_typid_copy_k: (                   {data type is a copy of another}
      copy_symbol_p: code_symbol_p_t;  {points to copied data type symbol}
      copy_dtype_p: code_dtype_p_t;    {points to ultimate data type definition}
      );
code_typid_int_k: (                    {data type is an integer}
      int_sign: boolean;               {integer is signed, not unsigned}
      int_exactbits: boolean;          {must act as if exactly BITS_MIN bits wide}
      );
code_typid_enum_k: (                   {data type is enumerated}
      enum_first_p: code_symbol_p_t;   {points to first enumerated name}
      enum_last_p: code_symbol_p_t;    {points to last enumerated name}
      );
code_typid_float_k: (                  {data type is floating point}
      );
code_typid_bool_k: (                   {data type is boolean}
      );
code_typid_char_k: (                   {data type is character}
      );
code_typid_agg_k: (                    {data type is aggregate}
      agg_symtab_p: code_symtab_p_t;   {to symbol table for field names}
      agg_first_p: code_symbol_p_t;    {points to symbol def for first field}
      );
code_typid_array_k: (                  {data type is an array}
      ar_dtype_ele_p: code_dtype_p_t;  {data type of final array elements}
      ar_dtype_rem_p: code_dtype_p_t;  {dtype of array "remainder" after 1st subscr}
      ar_ind_first_p: code_exp_p_t;    {pnt to exp for first legal subscript value}
      ar_ind_last_p: code_exp_p_t;     {pnt to exp for last val, NIL = unlimited}
      ar_ind_n: sys_int_machine_t;     {number of indicies in first subscript}
      ar_n_subscr: sys_int_machine_t;  {number of subscripts}
      ar_string: boolean;              {TRUE if one-dimensional array of characters}
      );
code_typid_set_k: (                    {data type is a set}
      set_dtype_p: code_dtype_p_t;     {points to data type of set elements}
      set_n_ent: sys_int_machine_t;    {CODE_VAL_SET_T array entries needed for set value}
      set_dtype_final: boolean;        {TRUE if final data type definately known}
      );
code_typid_range_k: (                  {data type is a subrange of another data type}
      range_dtype_p: code_dtype_p_t;   {points to base data type of subrange}
      range_first_p: code_exp_p_t;     {expression for start of range value}
      range_last_p: code_exp_p_t;      {expression of end of range value}
      range_ord_first: sys_int_max_t;  {ordinal value of first possible value}
      range_n_vals: sys_int_max_t;     {number of values}
      );
code_typid_proc_k: (                   {data type is a procedure}
      proc_p: code_proc_p_t;           {points to procedure interface definition}
      );
code_typid_pnt_k: (                    {data type is a pointer}
      pnt_dtype_p: code_dtype_p_t;     {pointed to data type, NIL = UNIV_PTR}
      );
code_typid_vstr_k: (                   {string with current and max lengths}
      vstr_max: sys_int_machine_t;     {max string length}
      );
code_typid_flxstr_k: (                 {string with extendable length}
      );
    end;
{
*   Constants.
}
  code_val_set_t =                     {one bit for each possible element in a set}
    array[0..0] of sys_int_conv32_t;   {32 bits stored in each array element}

  code_value_t = record                {data describing a known constant value}
    comm_p: code_comm_p_t;             {related comments}
    typid: code_typid_k_t;             {data type ID of the constant}
    case code_typid_k_t of             {different data for each data type}
code_typid_int_k: (                    {data type is an integer}
      int_val: sys_int_max_t;
      );
code_typid_enum_k: (                   {data type is enumerated}
      enum_sym_p: code_symbol_p_t;
      );
code_typid_float_k: (                  {data type is floating point}
      float_val: double;
      );
code_typid_bool_k: (                   {data type is boolean}
      bool_val: boolean;
      );
code_typid_char_k: (                   {data type is character}
      char_val: char;
      );
code_typid_array_k: (                  {data type is array}
      ar_str_p: string_var_p_t;        {points to string if ar is string data type}
      );
code_typid_set_k: (                    {data type is a SET}
      set_dtype_p: code_dtype_p_t;     {points to data type descriptor for SET}
      set_val_p: code_val_set_p_t;     {set value, one bit for each possible element}
      );
code_typid_pnt_k: (                    {data type is a pointer}
      pnt_dtype_p: code_dtype_p_t;     {points to data type desc of pointer}
      pnt_exp_p: code_exp_p_t;         {pnt to variable being referenced, may be NIL}
      );
    end;
{
*   Symbols, symbol tables, and scopes.  Symbols are names stored in symbol
*   tables.  Symbol tables are within scopes.  There can be one symbol table of
*   each type in a scope.  Scopes are tree-structured, starting from the root
*   scope.
}
  {
  *   WARNING: Module CODE_SYMTYPE contains a table of text names for each
  *   symbol type.  This table must be updated if CODE_SYMTYPE_K_T is changed.
  }
  code_symtype_k_t = (                 {symbol type IDs, update CODE_SYMTYPE if changed}
    code_symtype_invalid_k,            {invalid, not used on real symbol}
    code_symtype_unk_k,                {unknown, not used on real symbol}
    code_symtype_undef_k,              {symbol exists, but not defined yet}
    code_symtype_scope_k,              {sub-scope within parent scope}
    code_symtype_memory_k,             {memory}
    code_symtype_memreg_k,             {memory region}
    code_symtype_adrsp_k,              {address space}
    code_symtype_adrreg_k,             {address region}
    code_symtype_const_k,              {constant, value known at compile time}
    code_symtype_enum_k,               {name of an enumerated type, constant int}
    code_symtype_dtype_k,              {data type definition}
    code_symtype_field_k,              {field name in aggregate data type}
    code_symtype_var_k,                {variable}
    code_symtype_alias_k,              {alias for other symbol reference}
    code_symtype_proc_k,               {procedure, function or subroutine}
    code_symtype_prog_k,               {top level program name}
    code_symtype_com_k,                {common block}
    code_symtype_module_k,             {name of separately compiled source module}
    code_symtype_label_k);             {label (GOTO target)}
  code_symtype_t = set of code_symtype_k_t;

  code_symflag_k_t = (                 {independent one bit flags for each symbol}
    code_symflag_def_k,                {symbol is defined, not just referenced}
    code_symflag_used_k,               {this symbol is actually used}
    code_symflag_following_k,          {currently following symbol references}
    code_symflag_following_dt_k,       {currently following data type references}
    code_symflag_followed_k,           {completed following symbol references}
    code_symflag_writing_k,            {symbol is being written to output file}
    code_symflag_writing_dt_k,         {currently writing data type definition}
    code_symflag_written_k,            {symbol has been written to output file}
    code_symflag_created_k,            {symbol was created by translator}
    code_symflag_intrinsic_in_k,       {symbol is intrinsic to input language}
    code_symflag_intrinsic_out_k,      {symbol is intrinsic to output language}
    code_symflag_global_k,             {symbol will be globally known to linker}
    code_symflag_extern_k,             {symbol lives externally to this module}
    code_symflag_defnow_k,             {will be defined now, used by back end}
    code_symflag_ok_sname_k,           {OK if other out symbol is given same name}
    code_symflag_static_k);            {symbol represents storage that is static}
  code_symflag_t = set of code_symflag_k_t;

  code_sym_field_t = record            {unique data for sym that is field of aggregate}
    dtype_p: code_dtype_p_t;           {points to data type for this field}
    parent_p: code_dtype_p_t;          {points to data type that includes this field}
    next_p: code_symbol_p_t;           {points to symbol for next field}
    ofs_adr: sys_int_adr_t;            {machine adr offset from aggregate start}
    ofs_bits: sys_int_machine_t;       {additional bits offset}
    variant: sys_int_machine_t;        {sequential overlay number, 0 = base}
    value: code_value_t;               {user ID for this overlay}
    end;

  code_sym_proc_t = record             {unique data for sym that is procedure}
    proc_p: code_proc_p_t;             {procedure descriptor}
    varscope_p: code_scope_p_t;        {points to scope for rest of procedure}
    vardtype_p: code_dtype_p_t;        {points to data type for the procedure (not func ret)}
    varfuncvar_p: code_symbol_p_t;     {points to function return "variable" symbol}
    varmemreg_p: code_memreg_ent_p_t;  {points to list of mem regions routine may be in}
    end;

  code_sym_var_t = record              {unique data for sym that is a variable}
    dtype_p: code_dtype_p_t;           {pointer to data type definition}
    val_p: code_exp_p_t;               {points to initial value expression, if any}
    arg_p: code_dumarg_p_t;            {points to arg descriptor if dummy argument}
    com_p: code_symbol_p_t;            {points to common block symbol if in common}
    next_p: code_symbol_p_t;           {points to next var in common block}
    memreg_p: code_memreg_ent_p_t;     {points to list of mem regions variable may be in}
    end;

  code_symbol_t = record               {all the data about one symbol}
    name_p: string_var_p_t;            {to symbol name string}
    pos: fline_cpos_t;                 {position of definition in source code}
    comm_p: code_comm_p_t;             {related comments}
    symtab_p: code_symtab_p_t;         {to symbol table this symbol is in}
    subscope_p: code_scope_p_t;        {to subordinate scope, if any}
    subtab_p: code_symtab_p_t;         {to subordinate symbol table, if any}
    flags: code_symflag_t;             {set of individual flags}
    app_p: univ_ptr;                   {arbitrary pointer to app-specific data}
    symtype: code_symtype_k_t;         {symbol type, use CODE_SYMTYPE_xxx_K}
    case code_symtype_k_t of           {different data for each symbol type}
code_symtype_undef_k: (                {symbol not defined yet, only name known}
      );
code_symtype_scope_k: (                {symbol is sub-scope within parent scope}
      );
code_symtype_memory_k: (               {memory}
      memory_p: code_memory_p_t;       {points to memory descriptor}
      );
code_symtype_memreg_k: (               {memory region}
      memreg_p: code_memregion_p_t;    {points to memory region descriptor}
      );
code_symtype_adrsp_k: (                {address space}
      adrsp_p: code_adrspace_p_t;      {points to address space descriptor}
      );
code_symtype_adrreg_k: (               {address region}
      adrreg_p: code_adrregion_p_t;    {points to address region descriptor}
      );
code_symtype_const_k: (                {symbol is a constant}
      const_exp_p: code_exp_p_t;       {points to expression defining constant value}
      );
code_symtype_enum_k: (                 {symbol is value of an enumerated type}
      enum_prev_p: code_symbol_p_t;    {points to name for next lower value}
      enum_next_p: code_symbol_p_t;    {points to name for next higher value}
      enum_dtype_p: code_dtype_p_t;    {points to enumerated data type}
      enum_ordval: sys_int_machine_t;  {ordinal value of this name}
      );
code_symtype_dtype_k: (                {symbol is a data type}
      dtype_dtype_p: code_dtype_p_t;   {points to data type descriptor}
      );
code_symtype_field_k: (                {symbol is a field name of aggregate data type}
      field_p: code_sym_field_p_t;     {to specific data for this symbol type}
      );
code_symtype_var_k: (                  {symbol is a variable}
      var_p: code_sym_var_p_t;         {to specific data for this symbol type}
      );
code_symtype_alias_k: (                {symbol is an alias for another symbol reference}
      alias_symref_p: code_symref_p_t; {points to symbol reference alias expands to}
      );
code_symtype_proc_k: (                 {symbol is a procedure}
      proc_p: code_sym_proc_p_t;       {to specific data for this symbol type}
      );
code_symtype_prog_k: (                 {symbol is a program name}
      prog_scope_p: code_scope_p_t;    {to scope inside the program}
      prog_memreg_p: code_memreg_ent_p_t; {points to list of mem regions program may be in}
      );
code_symtype_com_k: (                  {symbol is a common block name}
      com_first_p: code_symbol_p_t;    {points to first variable in common block}
      com_size: sys_int_max_t;         {common block size in machine addresses}
      com_memreg_p: code_memreg_ent_p_t; {points to list of mem regions block may be in}
      );
code_symtype_module_k: (               {symbol is a module name}
      );
code_symtype_label_k: (                {symbol is a statement label}
      label_ele_p: code_ele_p_t;       {points to code element for the label}
      );
    end;

  code_symtab_t = record               {data for one symbol table}
    scope_p: code_scope_p_t;           {to scope for general symbol tables}
    parsym_p: code_symbol_p_t;         {to parent symbol for private tables}
    hash: string_hash_handle_t;        {handle to hash table symbols stored in}
    end;

  code_symtab_get_t = record           {state for getting symbols from symbol table}
    pos: string_hash_pos_t;            {position within hash table}
    valid: boolean;                    {POS is valid, is at a hash table entry}
    end;

  code_scope_t = record                {data about a scope or namespace}
    parscope_p: code_scope_p_t;        {to parent scope, NIL at root}
    symbol_p: code_symbol_p_t;         {to symbol defining this scope, NIL at root}
    symtab_scope_p: code_symtab_p_t;   {to table for symbols that have subordinate scopes}
    symtab_vcon_p: code_symtab_p_t;    {to table for variables and constants}
    symtab_dtype_p: code_symtab_p_t;   {to table for data types}
    symtab_label_p: code_symtab_p_t;   {to table for labels}
    symtab_other_p: code_symtab_p_t;   {to table for all other symbol types}
    end;

  code_syent_t = record                {simple symbols list entry}
    next_p: code_syent_p_t;            {to next list entry}
    sym_p: code_symbol_p_t;            {symbol for this list entry}
    end;

  code_symlist_ent_t = record          {one entry in fully linked symbols list}
    prev_p: code_symlist_ent_p_t;      {to previous entry, NIL at first}
    next_p: code_symlist_ent_p_t;      {to next entry, NIL at last}
    sym_p: code_symbol_p_t;            {to the symbol of this list entry}
    end;

  code_symlist_t = record              {fully linked symbols list}
    mem_p: util_mem_context_p_t;       {to memory context for list data}
    n: sys_int_machine_t;              {number of entries in the list}
    first_p: code_symlist_ent_p_t;     {to first list entry, NIL on empty list}
    last_p: code_symlist_ent_p_t;      {to last list entry, NIL on empty list}
    end;
{
*   Expressions.
}
  code_rwflag_k_t = (                  {permissions to read/write entity}
    code_rwflag_read_k,                {entity may be read from}
    code_rwflag_write_k);              {entity may be written to}
  code_rwflag_t = code_rwflag_k_t;

  code_expflag_k_t = (                 {individual flags relating to expressions}
    code_expflag_tyhard_k,             {hard data type, not flexible based on usage}
    code_expflag_eval_k,               {attempted to resolve constant value}
    code_expflag_val_k);               {resolved to constant value}
  code_expflag_t = set of code_expflag_k_t;

  code_opid_k_t = (                    {known operations that can be performed on data}
    code_opid_abs_k,                   {absolute value}
    code_opid_add_k,                   {sum of arguments}
    code_opid_addr_k,                  {address of}
    code_opid_align_k,                 {get min alignment needed for object or data type}
    code_opid_andint_k,                {bitwise AND}
    code_opid_andlog_k,                {logical AND}
    code_opid_andthen_k,               {logical AND, evaluated in order, early exit}
    code_opid_atan_k,                  {arctangent given slope as ratio of 2 numbers}
    code_opid_complt_k,                {< comparison}
    code_opid_comple_k,                {<= comparison}
    code_opid_compeq_k,                {= comparison}
    code_opid_compne_k,                {<> comparison}
    code_opid_compge_k,                {>= comparison}
    code_opid_compgt_k,                {> comparison}
    code_opid_cos_k,                   {cosine, argument in radians}
    code_opid_dec_k,                   {next smaller value of}
    code_opid_div_k,                   {arg1 divided by each remaining argument}
    code_opid_divi_k,                  {integer division, arg1 div by remaining args}
    code_opid_exp_k,                   {E to power of argument}
    code_opid_first_k,                 {first possible value of}
    code_opid_in_k,                    {TRUE if arg1 is member of set arg2}
    code_opid_inc_k,                   {next greater value of}
    code_opid_invint_k,                {bitwise inversion}
    code_opid_invlog_k,                {logical inversion}
    code_opid_invsig_k,                {sign inversion (negate)}
    code_opid_char_k,                  {integer character code to character}
    code_opid_int_near_k,              {convert to integer, round to nearest}
    code_opid_int_zero_k,              {convert to integer, round towards zero}
    code_opid_last_k,                  {last possible value of}
    code_opid_ln_k,                    {logarithm base E}
    code_opid_max_k,                   {maximum value of all arguments}
    code_opid_min_k,                   {minimum value of all arguments}
    code_opid_mult_k,                  {product of a arguments}
    code_opid_offset_k,                {machine address offset of field in aggregate}
    code_opid_ord_val_k,               {ordinal value of}
    code_opid_orelse_k,                {logical OR, evaluated in order, early exit}
    code_opid_orint_k,                 {bitwise OR}
    code_opid_orlog_k,                 {logical OR}
    code_opid_pwr_k,                   {arg1 to power of arg2}
    code_opid_rem_k,                   {remainder of arg1 integer divided by arg2}
    code_opid_setrem_k,                {remove elements arg2 from set arg1}
    code_opid_setisect_k,              {set intersection}
    code_opid_setun_k,                 {set union}
    code_opid_shift_lo_k,              {logical shift arg1 by arg2 bits right, arg2 signed}
    code_opid_shiftl_lo_k,             {logical shift left arg1 by arg2 bits}
    code_opid_shiftr_ar_k,             {arithmetic shift right arg1 by arg2 bits}
    code_opid_shiftr_lo_k,             {logical shift right arg1 by arg2 bits}
    code_opid_sin_k,                   {sine, arguments in radians}
    code_opid_size_align_k,            {align-padded size of}
    code_opid_size_char_k,             {number of characters that can fit}
    code_opid_size_min_k,              {minimum size of, no padding for alignment}
    code_opid_sqr_k,                   {square of}
    code_opid_sqrt_k,                  {square root of}
    code_opid_strint_k,                {string from integer}
    code_opid_strfp_k,                 {string from floating point}
    code_opid_sub_k,                   {arg1 minus each remaining argument}
    code_opid_tycast_k,                {hard re-cast of bits to different data type}
    code_opid_xorint_k,                {bitwise exclusive OR}
    code_opid_xorlog_k,                {logical exclusive OR}
    code_opid_setinv_k);               {set inversion}

  code_expid_k_t = (                   {IDs for different types of expressions}
    code_expid_const_k,                {constant}
    code_expid_var_k,                  {variable or field in aggregate}
    code_expid_func_k,                 {value of function return}
    code_expid_set_k,                  {set}
    code_expid_arele_k,                {values for array elements}
    code_expid_range_k,                {range of values}
    code_expid_op_k);                  {result of operation}

  code_exp_t = record                  {expression that supplies a value}
    comm_p: code_comm_p_t;             {related comments}
    pos: fline_cpos_t;                 {starting position of exp in source code}
    dtype_p: code_dtype_p_t;           {data type of the expression}
    val_p: code_value_p_t;             {expression value, if known}
    flag: code_expflag_t;              {modifier flags}
    rwflag: code_rwflag_t;             {read/write permission for this expression}
    expid: code_expid_k_t;             {ID for the kind of expression this is}
    case code_expid_k_t of
code_expid_const_k: (                  {constant, value in VAL field}
      const_sym_p: code_symbol_p_t;    {points to symbol if symbolic constant}
      );
code_expid_var_k: (                    {variable reference}
      var_ref_p: code_symref_p_t;      {points to reference to variable symbol}
      );
code_expid_func_k: (                   {returned value of a function}
      func_ref_p: code_symref_p_t;     {points to function call symbol reference}
      func_proc_p: code_proc_p_t;      {points to function template}
      func_arg_p: code_call_arg_p_t;   {points to list of call arguments}
      );
code_expid_set_k: (                    {set value}
      set_ele_p: code_explist_p_t;     {list of elements or ranges of elements}
      );
code_expid_arele_k: (                  {set of array elements}
      arele_start: sys_int_machine_t;  {start index ordinal with this val, first = 0}
      arele_n: sys_int_machine_t;      {number of indicies with this value}
      arele_exp_p: code_exp_p_t;       {points to expression for elements value}
      );
code_expid_range_k: (                  {range of values}
      range_st_p: code_exp_p_t;        {expression for start of range value}
      range_en_p: code_exp_p_t;        {expression for end of range value}
      );
code_expid_op_k: (                     {result of operation}
      op_id: code_opid_k_t;            {indicates the specific operation}
      op_arg_p: code_explist_p_t;      {pointer to list of arguments}
      );
    end;

  code_explist_t = record              {list of expressions}
    next_p: code_explist_p_t;          {to next expression in the list}
    exp_p: code_exp_p_t;               {to expression for this list entry}
    end;

  code_refmodid_k_t = (                {all the different variable modifier types}
    code_refmodid_unpnt_k,             {pointer dereference}
    code_refmodid_subscr_k,            {expression for next less sig subscript}
    code_refmodid_field_k);            {field name in current aggregate}

  code_refmod_t = record               {data for one variable modifier}
    next_p: code_refmod_p_t;           {points to next modifier in chain}
    modtyp: code_refmodid_k_t;         {what kind of modifier this is}
    case code_refmodid_k_t of
code_refmodid_unpnt_k: (               {dereference parent}
      );
code_refmodid_subscr_k: (              {next less significant subscript of array}
      subscr_exp_p: code_exp_p_t;      {points to expression for this subscript}
      subscr_first: boolean;           {TRUE if first subscript of set}
      subscr_last: boolean;            {TRUE if last subscript of set}
      );
code_refmodid_field_k: (               {field within parent}
      field_pos: fline_cpos_t;         {starting position in source code}
      field_sym_p: code_symbol_p_t;    {points to symbol for this field name}
      );
    end;

  code_refid_k_t = (                   {IDs for direct symbol reference types}
    code_refid_var_k,                  {variable}
    code_refid_dtype_k,                {data type}
    code_refid_rout_k,                 {routine}
    code_refid_const_k,                {named constant}
    code_refid_com_k);                 {common block}

  code_symref_t = record               {symbol reference}
    sym_p: code_symbol_p_t;            {the symbol being referenced}
    pos: fline_cpos_t;                 {starting position in source code}
    comm_p: code_comm_p_t;             {related comments}
    mod_p: code_refmod_p_t;            {list of modifiers applied to this symbol}
    rwflag: code_rwflag_t;             {read/write permission for this "variable"}
    refid: code_refid_k_t;             {ID for final resolved symbol ref type}
    case code_refid_k_t of
code_refid_var_k: (                    {variable}
      var_dtype_p: code_dtype_p_t;     {points to final data type}
      );
code_refid_dtype_k: (                  {data type}
      dtype_dtype_p: code_dtype_p_t;   {points to final data type}
      );
code_refid_rout_k: (                   {routine}
      rout_proc_p: code_proc_p_t;      {points to template of called routine}
      );
code_refid_const_k: (                  {a named constant reference}
      const_value_p: code_value_p_t;   {points to final resolved value}
      );
code_refid_com_k: (                    {a common block reference}
      com_sym_p: code_symbol_p_t;      {points to final common block symbol}
      );
    end;
{
*   Procedures and their arguments and return values.
}
  code_argflag_k_t = (                 {individual flags for arguments to routines}
    code_argflag_pass_unk_k,           {passing method unknown or not set yet}
    code_argflag_pass_val_k,           {passed by value}
    code_argflag_pass_ref_k,           {passed by reference}
    code_argflag_dtany_k,              {any data type allowed}
    code_argflag_dtarlen_k);           {array type, but any length of last subscript allowed}
  code_argflag_t = set of code_argflag_k_t;

  code_proc_arg_t = record             {template for one procedure argument}
    next_p: code_proc_arg_p_t;         {points to data about next arg}
    comm_p: code_comm_p_t;             {related comments}
    proc_p: code_proc_p_t;             {points to interface definition of the procedure}
    pos: fline_cpos_t;                 {position of definition in source code}
    name_p: string_var_p_t;            {pnt to arg name if routine template}
    dtype_p: code_dtype_p_t;           {points to required data type for this arg}
    rwflag: code_rwflag_t;             {routine's read/write permission of this arg}
    flag: code_argflag_k_t;            {modifier flags}
    end;

  code_procflag_k_t = (                {flags for routines}
    code_procflag_noreturn_k);         {routine will never return to caller}
  code_procflag_t = set of code_procflag_k_t;

  code_proc_t = record                 {external interface data for one procedure}
    comm_p: code_comm_p_t;             {related comments}
    sym_p: code_symbol_p_t;            {points to routine name symbol, if any}
    dtype_func_p: code_dtype_p_t;      {points to function val data type, if any}
    n_args: sys_int_machine_t;         {total number of call arguments}
    flags: code_procflag_t;            {set of one-bit flags}
    arg_p: code_proc_arg_p_t;          {points to list of call arguments templates}
    end;

  code_call_arg_t = record             {argument being passed to a routine}
    next_p: code_call_arg_p_t;         {points to next call argument of this call}
    comm_p: code_comm_p_t;             {related comments}
    proc_p: code_proc_p_t;             {points to procedure definition}
    arg_p: code_proc_arg_p_t;          {points to the argument template}
    exp_p: code_exp_p_t;               {points to value being passed}
    end;

  code_dumarg_t = record               {call argument as seen inside the routine}
    next_p: code_dumarg_p_t;           {points to next dummy argument of this routine}
    comm_p: code_comm_p_t;             {related comments}
    proc_p: code_proc_p_t;             {points to the routine definition}
    arg_p: code_proc_arg_p_t;          {points to the argument template}
    sym_p: code_symbol_p_t;            {point to arg symbol in actual routine}
    rwflag: code_rwflag_t;             {arg read/write permission from inside proc}
    end;
{
*   Code elements.
}
  code_caseval_t = record              {one value of this code case to pick from}
    next_p: code_caseval_p_t;          {points to next value for this code case}
    comm_p: code_comm_p_t;             {related comments}
    exp_p: code_exp_p_t;               {points to expression for this value}
    end;

  code_case_t = record                 {one case in list of cases}
    next_p: code_case_p_t;             {next case in the list}
    comm_p: code_comm_p_t;             {related comments}
    vals_p: code_caseval_p_t;          {values for selecting this case}
    code_p: code_ele_p_t;              {executable code for this case}
    end;

  code_incdir_k_t = (                  {loop increment direction flag}
    code_incdir_up_k,                  {increment is positive}
    code_incdir_down_k,                {increment is negative}
    code_incdir_unk_k);                {increment direction is unknown}

  code_iterid_k_t = (                  {ID for loop iteration type}
    code_iterid_cnt_k,                 {counted loop}
    code_iterid_while_k);              {loop while condition true}

  code_iter_t = record                 {block iteration setup}
    iterid: code_iterid_k_t;           {type of this iteration}
    case code_iterid_k_t of
code_iterid_cnt_k: (                   {counted loop}
      cnt_var_p: code_symref_p_t;      {points to counting variable}
      cnt_exp_start_p: code_exp_p_t;   {points to starting value expression}
      cnt_exp_end_p: code_exp_p_t;     {points to ending value expression}
      cnt_exp_inc_p: code_exp_p_t;     {points to increment value expression}
      cnt_inc_dir: code_incdir_k_t;    {up/down/unknown increment direction}
      );
code_iterid_while_k: (                 {loop while condition true}
      );
    end;

  code_ele_k_t = (                     {IDs for each type of code element}
    code_ele_module_k,                 {start of a grouping of routines}
    code_ele_prog_k,                   {start of top level program}
    code_ele_rout_k,                   {start of a routine}
    code_ele_exec_k,                   {points to chain of executable code}
    {
    *   Elements only used within executable code.
    }
    code_ele_label_k,                  {label (GOTO target)}
    code_ele_call_k,                   {subroutine call}
    code_ele_assign_k,                 {assignment to a variable}
    code_ele_goto_k,                   {unconditional transfer of control}
    code_ele_pick_k,                   {execute one or more code cases}
    code_ele_if_k,                     {IF ... THEN ... ELSE ... statement}
    code_ele_block_k,                  {nested block of code}
    code_ele_next_k,                   {to next iteration of block}
    code_ele_exit_k,                   {end execution of block}
    code_ele_return_k,                 {return from subroutine}
    code_ele_alias_k,                  {block with symbol aliases applied}
    code_ele_discard_k,                {call function, but discard its return value}
    code_ele_write_k,                  {write string to standard output}
    code_ele_write_eol_k);             {write end of line to standard output}

  code_ele_t = record                  {one code element}
    next_p: code_ele_p_t;              {points to next successive element, NIL = end}
    pos: fline_cpos_t;                 {starting position in source code}
    comm_p: code_comm_p_t;             {related comments}
    ele: code_ele_k_t;                 {ID for this element type}
    case code_ele_k_t of
code_ele_module_k: (                   {routines in one source module}
      module_sym_p: code_symbol_p_t;   {points to module name symbol}
      module_p: code_ele_p_t;          {points to code in this module}
      );
code_ele_prog_k: (                     {start of new program}
      prog_sym_p: code_symbol_p_t;     {points to program name symbol}
      prog_p: code_ele_p_t;            {points to code in this program}
      );
code_ele_rout_k: (                     {start of a routine}
      rout_sym_p: code_symbol_p_t;     {points to routine name symbol}
      rout_p: code_ele_p_t;            {points to code in this routine}
      );
code_ele_exec_k: (                     {chain of executable code}
      exec_p: code_ele_p_t;            {points to first code element in chain}
      );
code_ele_label_k: (                    {a label exists here}
      label_sym_p: code_symbol_p_t;    {points to label symbol}
      );
code_ele_call_k: (                     {subroutine call}
      call_ref_p: code_symref_p_t;     {points to subroutine name reference}
      call_proc_p: code_proc_p_t;      {points to template for called routine}
      call_arg_p: code_call_arg_p_t;   {points to list of call arguments}
      );
code_ele_assign_k: (                   {assignment statement}
      assign_var_p: code_symref_p_t;   {points to target variable reference}
      assign_exp_p: code_exp_p_t;      {points to assignment value expression}
      );
code_ele_goto_k: (                     {unconditional GOTO}
      goto_sym_p: code_symbol_p_t;     {points to label symbol}
      );
code_ele_pick_k: (                     {execute one or more code cases}
      case_exp_p: code_exp_p_t;        {expression for selecting case}
      case_case_p: code_case_p_t;      {list of cases to select from}
      case_none_p: code_ele_p_t;       {code when no match, may be NIL}
      );
code_ele_if_k: (                       {IF ... THEN ... ELSE ... statement}
      if_exp_p: code_exp_p_t;          {pointer to boolean expression}
      if_true_p: code_ele_p_t;         {code for TRUE case}
      if_false_p: code_ele_p_t;        {code for FALSE case}
      );
code_ele_block_k: (                    {nested block of code}
      block_iter_p: code_iter_p_t;     {block iteration setup, like counted loop}
      block_code_p: code_ele_p_t;      {code inside the block}
      block_next_p: code_ele_p_t;      {code to execute before each new iteration}
      block_exit_p: code_ele_p_t;      {code to execute before exiting block}
      );
code_ele_next_k: (                     {to next iteration of current block}
      next_block_p: code_ele_p_t;      {points to start of the block}
      );
code_ele_exit_k: (                     {end execution of current block}
      exit_block_p: code_ele_p_t;      {points to start of the block}
      );
code_ele_return_k: (                   {return from subroutine}
      );
code_ele_alias_k: (                    {aliases in effect over a block of code}
      alias_scope_p: code_scope_p_t;   {points to scope of alias symbols}
      alias_code_p: code_ele_p_t;      {points to code that can use aliases}
      alias_list_p: code_syent_p_t;    {list of aliases that apply in block}
      );
code_ele_discard_k: (                  {call function but discard its return value}
      discard_exp_p: code_exp_p_t;     {expression which is the function reference}
      );
code_ele_write_k: (                    {write string to standard output}
      write_exp_p: code_exp_p_t;       {string expression to write value of}
      );
code_ele_write_eol_k: (                {write end of line to standard output}
      );
    end;
{
*   Top level state and library management.
}
  code_inicfg_t = record               {configuration for a new library use}
    mem_p: util_mem_context_p_t;       {points to parent mem context}
    symlen_max: sys_int_machine_t;     {max supported length of symbol names}
    n_symbuck: sys_int_machine_t;      {number of hash buckets in symbol tables}
    end;

  code_config_t = record               {code lib configuration settings}
    symlen_max: sys_int_machine_t;     {max supported symbol length}
    n_symbuck: sys_int_machine_t;      {N hash buckets in symbol tables, power of 2}
    end;

  code_parse_t = record                {parsing state that needs to be visible to CODE lib}
    pos: fline_cpos_t;                 {current parsing position}
    level: sys_int_machine_t;          {current block nesting level, 0 = top}
    nextlevel: sys_int_machine_t;      {lev of next statement}
    end;

  code_default_t = record              {default settings}
    int_bits: sys_int_machine_t;       {min required bits in integer type}
    end;

  code_p_t = ^code_t;
  code_t = record                      {state for one use of this library}
    mem_p: util_mem_context_p_t;       {context for all dyn mem of this CODE lib use}
    config: code_config_t;             {configuration parameters for this CODE lib instance}
    default: code_default_t;           {various default settings}
    parse: code_parse_t;               {parsing state visible to CODE lib}
    comm_block_p: code_comm_p_t;       {to current hiearchy of block comments}
    comm_eol_p: code_comm_p_t;         {to latest end of line comment}
    scope_root: code_scope_t;          {root scope}
    scope_p: code_scope_p_t;           {to current scope}
    memsym_p: code_symtab_p_t;         {to memory and adr space symbol table in MEM scope}
    dtcomm_p: code_symtab_p_t;         {to canonical data types sym table in DTYPE scope}
    end;
{
*   Functions and subroutines.
}
procedure code_adrreg_find (           {find adr region by name, error if not exist}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of adr region to find}
  out     adrreg_p: code_adrregion_p_t; {returned pointer to the adr region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_adrreg_new (            {create a new named address region}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new adr region}
  in      adrname: univ string_var_arg_t; {name of address space this region is within}
  out     adrreg_p: code_adrregion_p_t; {returned pointer to the adr region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_adrreg_memreg_add (     {add mapped-to mem region to address region}
  in out  code: code_t;                {CODE library use state}
  in out  adrreg: code_adrregion_t;    {address region to add mapping to}
  in var  memreg: code_memregion_t;    {memory region being added}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_adrsp_find (            {find adr space by name, error if not exist}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of adr space to find}
  out     adrsp_p: code_adrspace_p_t;  {returned pointer to the adr space, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_adrsp_new (             {create a new named address space}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new adr space}
  out     adrsp_p: code_adrspace_p_t;  {returned pointer to the adr space, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_alloc_global (          {alloc mem under CODE context, can't individually dealloc}
  in out  code: code_t;                {CODE library use state}
  in      size: sys_int_adr_t;         {amount of memory to allocate, bytes}
  out     new_p: univ_ptr);            {returned pointer to the new memory}
  val_param; extern;

procedure code_alloc_symtab (          {alloc perm mem from symbol table context}
  in out  symtab: code_symtab_t;       {context to allocate memory from}
  in      size: sys_int_adr_t;         {amount of memory to allocate, bytes}
  out     new_p: univ_ptr);            {returned pointer to the new memory}
  val_param; extern;

procedure code_comm_find (             {returns pointer to comments applying at position}
  in out  code: code_t;                {CODE library use state}
  in      lnum: sys_int_machine_t;     {sequential line number}
  in      level: sys_int_machine_t;    {0-N nesting level}
  out     comm_p: code_comm_p_t);      {returned pointer to comments, may be NIL}
  val_param; extern;

procedure code_comm_keep (             {keep last block comment in previous comm list}
  in out  code: code_t;                {CODE library use state}
  in      lnum: sys_int_machine_t;     {sequential line number of last comment line in block}
  out     comm_p: code_comm_p_t);      {comment created or added to, NIL on no matching block}
  val_param; extern;

procedure code_comm_new_block (        {add new block comment line to system}
  in out  code: code_t;                {CODE library use state}
  in      str_p: string_var_p_t;       {pointer to comment text}
  in      pos: fline_cpos_t;           {source position of new comment line}
  in      lnum: sys_int_machine_t;     {sequential line number}
  in      level: sys_int_machine_t;    {0-N nesting level}
  out     comm_p: code_comm_p_t);      {returned pointing to comment created or added to}
  val_param; extern;

procedure code_comm_new_eol (          {add new end of line comment to system}
  in out  code: code_t;                {CODE library use state}
  in      str_p: string_var_p_t;       {pointer to comment text}
  in      pos: fline_cpos_t;           {source position of new comment line}
  in      lnum: sys_int_machine_t;     {sequential line number}
  out     comm_p: code_comm_p_t);      {returned pointing to comment created or added to}
  val_param; extern;

procedure code_comm_show (             {show comment hierarchy on STDOUT, for debugging}
  in      comm_p: code_comm_p_t;       {pointer to comments, may be NIL}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_comm_show1 (            {show contents of single comment descriptor}
  in      comm: code_comm_t;           {the comment to show contents of}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_dtype_copy (            {make COPY data type}
  var in  orig: code_dtype_t;          {original data type to copy}
  out     copy: code_dtype_t);         {will be filled in as copy of ORIG}
  val_param; extern;

procedure code_dtype_find (            {find data type in curr scopes hierarchy}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of the data type}
  out     sym_p: code_symbol_p_t;      {to dtype symbol, NIL on not found}
  out     dtype_p: code_dtype_p_t);    {to final resolved dtype descriptor}
  val_param; extern;

procedure code_dtype_init (            {initialize a data type descriptor}
  in out  dtype: code_dtype_t);        {descriptor to initialize to default or benign}
  val_param; extern;

procedure code_dtype_int_find (        {find or make base integer data type}
  in out  code: code_t;                {CODE library use state}
  in      template: code_dtype_t;      {template integer data type, must not be copy}
  out     dtype_p: code_dtype_p_t);    {returned pointer to INT data type in root scope}
  val_param; extern;

procedure code_dtype_int_gnam (        {make generic name of integer data type}
  in out  code: code_t;                {CODE library use state}
  in      dtype: code_dtype_t;         {integer data type to make generic name of}
  in out  name: univ string_var_arg_t); {returned generic name}
  val_param; extern;

procedure code_dtype_new_intable (     {create and init new dtype in specific sym table}
  in out  code: code_t;                {CODE library use state}
  in out  symtab: code_symtab_t;       {symbol table to add the data type to}
  out     dtype_p: code_dtype_p_t);    {to newly created data type, initialized}
  val_param; extern;

procedure code_dtype_new_inscope (     {create and init new dtype in specific scope}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t;         {scope to create the data type within}
  out     dtype_p: code_dtype_p_t);    {to newly created data type, initialized}
  val_param; extern;

procedure code_dtype_new_sym (         {create new data type, connect to existing symbol}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t);         {sym to connect data type to, must not already be set}
  val_param; extern;

procedure code_dtype_resolve (         {resolve absolute data type}
  var in  dtype: code_dtype_t;         {dtype to resolve final type of}
  out     final_p: code_dtype_p_t);    {returned pointer to final (not copy) dtype}
  val_param; extern;

procedure code_dtype_sym_new (         {new data type symbol in curr scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of data type to create}
  out     sym_p: code_symbol_p_t);     {to new data type symbol, NIL on error}
  val_param; extern;

procedure code_dtype_sym_new_inscope ( {new dtype sym in specific scope, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of data type to create}
  in out  scope: code_scope_t;         {scope to create the data type within}
  out     sym_p: code_symbol_p_t);     {to new data type symbol, NIL on error}
  val_param; extern;

procedure code_dtype_sym_new_intable ( {new dtype sym in specific sym table, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of data type to create}
  in out  symtab: code_symtab_t;       {symbol table to add the data type to}
  out     sym_p: code_symbol_p_t);     {to new data type symbol, NIL on error}
  val_param; extern;

procedure code_dtype_sym_resolve (     {resolve dtype sym to final dtype descriptor}
  in out  code: code_t;                {CODE library use state}
  in      sym: code_symbol_t;          {data type symbol to resolve final type of}
  out     dtype_p: code_dtype_p_t);    {to final real (not copy) data type, NIL on not set}
  val_param; extern;

procedure code_dtype_sym_set (         {set dtype reference in symbol}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t;          {symbol to set dtype in, err if already set}
  in      template: code_dtype_t);     {template data type}
  val_param; extern;

procedure code_err_atline (            {show error, current loc, and bomb}
  in out  code: code_t;                {CODE library use state}
  in      subsys: string;              {name of subsystem, used to find message file}
  in      msg: string;                 {message name within subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      nparms: sys_int_machine_t);  {number of parameters in PARMS}
  options (val_param, noreturn, extern);

procedure code_err_atline_check (      {bomb on error, continue otherwise}
  in out  code: code_t;                {CODE library use state}
  in      stat: sys_err_t;             {error status, only bomb if indicates error}
  in      subsys: string;              {name of subsystem, used to find message file}
  in      msg: string;                 {message name within subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      nparms: sys_int_machine_t);  {number of parameters in PARMS}
  val_param; extern;

procedure code_errset_sym_exist (      {fill in STAT for symbol already exists}
  in      pos: string_hash_pos_t;      {symbol table position for existing symbol}
  out     stat: sys_err_t);            {filled in with appropriate error status}
  val_param; extern;

procedure code_lib_def (               {set library creation parameters to default}
  out     cfg: code_inicfg_t);         {parameters for creating a library use}
  val_param; extern;

procedure code_lib_end (               {end a use of the CODE library}
  in out  code_p: code_p_t);           {pointer to lib use state, returned NIL}
  val_param; extern;

procedure code_lib_new (               {create new use of the CODE library}
  in      inicfg: code_inicfg_t;       {configuration parameters}
  out     code_p: code_p_t;            {returned pointer to new library use state}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_mem_find (              {find memory by name, error if not exist}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of memory to find}
  out     mem_p: code_memory_p_t;      {returned pointer to the memory, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_mem_new (               {create a new named memory}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new memory}
  out     mem_p: code_memory_p_t;      {returned pointer to the memory, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_memreg_find (           {find memory region by name, error if not exist}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of memory region to find}
  out     memreg_p: code_memregion_p_t; {returned pointer to the mem region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_memreg_new (            {create a new named memory region}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of new memory region}
  in      memname: univ string_var_arg_t; {name of memory this region is within}
  out     memreg_p: code_memregion_p_t; {returned pointer to the mem region, NIL on err}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_memsym_find (           {find mem, mem region, adr, adr region by name}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of mem/adr symbol to find}
  out     memsym_p: code_symbol_p_t);  {returned pointer to symbol, NIL if none}
  val_param; extern;

procedure code_memsym_show (           {show details of one mem/adr symbol}
  in      sym: code_symbol_t;          {mem/adr symbol to show data of}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param; extern;

procedure code_memsym_show_all (       {show details of all mem/adr symbols}
  in out  code: code_t;                {CODE library use state}
  in      indent: sys_int_machine_t);  {number of spaces to indent all output}
  val_param; extern;

procedure code_scope_init (            {init a scope descriptor}
  out     scope: code_scope_t);        {descriptor to initialize}
  val_param; extern;

procedure code_scope_pop (             {pop back to parent scope}
  in out  code: code_t);               {CODE library use state}
  val_param; extern;

procedure code_scope_push (            {create new subordinate scope, make curr}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t);         {symbol defining the new scope}
  val_param; extern;

procedure code_scope_show (            {show scope tree}
  in out  code: code_t;                {CODE library use state}
  in      scope: code_scope_t;         {the scope to show}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_show_level_blank (      {indent to nesting level, write blanks only}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_show_level_dot (        {indent to nesting level, show dot per level}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_show_memaccs (          {write short names for each enabled mem access}
  in      accs: code_memaccs_t);       {set of memory access to show}
  val_param; extern;

procedure code_show_memattr (          {write short names for each enabled mem attribute}
  in      attr: code_memattr_t);       {set of memory attributes to show}
  val_param; extern;

procedure code_show_pos_parse (        {show the current parsing position on STDOUT}
  in out  code: code_t);               {CODE library use state}
  val_param; extern;

procedure code_show_pos (              {show source code position}
  in      pos: fline_cpos_t;           {character position to show}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_sym_curr (              {create symbol in current scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in      symtype: code_symtype_k_t;   {type of symbol to create}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_sym_find (              {find matching symbol in specific scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to find}
  in      scope: code_scope_t;         {scope to look for the symbol in}
  in      sytypes: code_symtype_t;     {allowable symbol types}
  out     sym_p: code_symbol_p_t);     {to found symbol, NIL = not found}
  val_param; extern;

procedure code_sym_inscope (           {create symbol in specific scope}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in      symtype: code_symtype_k_t;   {type of symbol to create}
  in out  scope: code_scope_t;         {scope to create the symbol within}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_sym_lookup (            {look up symbol name in a symbol table}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to look up}
  in      symtab: code_symtab_t;       {symbol table to look up name in}
  out     sym_p: code_symbol_p_t);     {returned pointer to symbol, NIL if not found}
  val_param; extern;

function code_sym_mem (                {get memory context symbol is allocated in}
  in      sym: code_symbol_t)          {symbol to get memory context of}
  :util_mem_context_p_t;               {pointer to symbol's mem context}
  val_param; extern;

procedure code_sym_new (               {create new symbol, err if exists}
  in out  code: code_t;                {CODE library use state}
  in      name: univ string_var_arg_t; {name of symbol to create}
  in out  table: code_symtab_t;        {symbol table to add the symbol to}
  out     sym_p: code_symbol_p_t;      {returned pointer to new symbol}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure code_sym_show (              {show symbol and any subordinate tree}
  in out  code: code_t;                {CODE library use state}
  in      sym: code_symbol_t;          {symbol to show description of}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

procedure code_symlist_add_scope (     {add all symbols in a scope to symbols list}
  in out  list: code_symlist_t;        {list to add symbols to}
  in      scope: code_scope_t);        {scope to add symbols from}
  val_param; extern;

procedure code_symlist_add_symtab (    {add symbols in symbol table to symbols list}
  in out  list: code_symlist_t;        {list to add symbols to}
  in var  symtab: code_symtab_t);      {symbolt table to add symbols from}
  val_param; extern;

procedure code_symlist_del (           {delete symbols list, deallocate resources}
  in out  list_p: code_symlist_p_t);   {to symbols list, returned NIL}
  val_param; extern;

procedure code_symlist_ent_add (       {add new entry to the end of the list}
  in out  list: code_symlist_t;        {list to add entry to}
  in var  sym: code_symbol_t);         {symbol to add}
  val_param; extern;

procedure code_symlist_ent_insert (    {insert new entry at specific point in list}
  in out  list: code_symlist_t;        {list to add entry to}
  in      bef_p: code_symlist_ent_p_t; {to list ent to insert after, NIL for at start}
  in var  sym: code_symbol_t);         {symbol to add}
  val_param; extern;

procedure code_symlist_ent_move (      {move entry within symbols list}
  in out  list: code_symlist_t;        {list to move entry within}
  in out  ent: code_symlist_ent_t;     {the entry to move}
  in out  bef_p: code_symlist_ent_p_t); {to list ent to move after, NIL for at start}
  val_param; extern;

procedure code_symlist_sort (          {sort list in alphabetical order}
  in out  list: code_symlist_t);       {the list to sort}
  val_param; extern;

procedure code_symlist_new (           {create new empty symbols list}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     list_p: code_symlist_p_t);   {returned pointer to new list}
  val_param; extern;

procedure code_symtab_exist_scope (    {make sure symbol table in scope exists}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t;         {scope symbol table will be within}
  in out  symtab_p: code_symtab_p_t);  {symbol table pointer in scope, filled in if NIL}
  val_param; extern;

procedure code_symtab_get (            {get next symbol in symbol table}
  in out  syget: code_symtab_get_t;    {symbol getting state}
  out     sym_p: code_symbol_p_t);     {to next symbol, NIL on hit end of table}
  val_param; extern;

procedure code_symtab_get_init (       {init for getting symbols from symbol table}
  out     syget: code_symtab_get_t;    {symbol getting state to initialize}
  in var  symtab: code_symtab_t);      {symbol table will be getting symbols from}
  val_param; extern;

procedure code_symtab_new_sym (        {create symbol table subordinate to a symbol}
  in out  code: code_t;                {CODE library use state}
  in out  sym: code_symbol_t;          {parent symbol for the new symbol table}
  out     symtab_p: code_symtab_p_t);  {to the new symbol table}
  val_param; extern;

function code_symtab_mem (             {get memory context of a symbol table}
  in      symtab: code_symtab_t)       {symbol table to get memory context of}
  :util_mem_context_p_t;               {pointer to symbol table's mem context}
  val_param; extern;

procedure code_symtab_show (           {show symbol table tree}
  in out  code: code_t;                {CODE library use state}
  in      symtab: code_symtab_t;       {symbol table to show}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param; extern;

function code_symtab_symtype (         {get symbol table for particular symbol type}
  in out  code: code_t;                {CODE library use state}
  in out  scope: code_scope_t;         {scope the symbol is within}
  in      symtype: code_symtype_k_t)   {type of symbol}
  :code_symtab_p_t;                    {pointer to the symbol table, will exist}
  val_param; extern;

function code_symtype_f_name (         {get the symbol type from the type name}
  in      tyname: univ string_var_arg_t) {symbol type name, case-insensitive}
  :code_symtype_k_t;                   {symbol type ID, INVALID when unrecognized}
  val_param; extern;

procedure code_symtype_t_name (        {get symbol type name from symbol type ID}
  in      symtype: code_symtype_k_t;   {symbol type ID}
  in out  name: univ string_var_arg_t); {returned symbol type name}
  val_param; extern;
