# ----------------------------------
# Options affecting listfile parsing
# ----------------------------------
# 影响列表文件解析的选项
with section("parse"):

  # Specify structure for custom cmake functions
  # 指定自定义cmake函数的结构
  additional_commands = { 'foo': { 'flags': ['BAR', 'BAZ'],
             'kwargs': {'DEPENDS': '*', 'HEADERS': '*', 'SOURCES': '*'}}}

  # Override configurations per-command where available
  # 覆盖特定命令的配置（如可用）
  override_spec = {}

  # Specify variable tags.
  # 指定变量标签
  vartags = []

  # Specify property tags.
  # 指定属性标签
  proptags = []

# -----------------------------
# Options affecting formatting.
# -----------------------------
# 影响格式化的选项
with section("format"):

  # Disable formatting entirely, making cmake-format a no-op
  # 完全禁用格式化，使cmake-format不执行任何操作
  disable = False

  # How wide to allow formatted cmake files
  # 允许格式化后的cmake文件宽度（字符数）
  line_width = 80

  # How many spaces to tab for indent
  # 制表符缩进的空格数
  tab_size = 2

  # If true, lines are indented using tab characters (utf-8 0x09) instead of...
  # 若为True，使用制表符（utf-8 0x09）而非空格进行缩进
  use_tabchars = False

  # If <use_tabchars> is True, then the value of this variable indicates how...
  # 当use_tabchars为True时，此变量指定如何处理部分缩进
  fractional_tab_policy = 'use-space'

  # If an argument group contains more than this many sub-groups...
  # 若参数组包含超过指定数量的子组，则强制垂直布局
  max_subgroups_hwrap = 2

  # If a positional argument group contains more than this many arguments...
  # 若位置参数组包含超过指定数量的参数，则强制垂直布局
  max_pargs_hwrap = 6

  # If a cmdline positional group consumes more than this many lines without...
  # 若命令行参数组在未嵌套情况下占用超过指定行数，则重新布局
  max_rows_cmdline = 2

  # If true, separate flow control names from their parentheses with a space
  # 若为True，在流程控制名称与其括号间添加空格
  separate_ctrl_name_with_space = False

  # If true, separate function names from parentheses with a space
  # 若为True，在函数名称与其括号间添加空格
  separate_fn_name_with_space = False

  # If a statement is wrapped to more than one line, than dangle the closing...
  # 若语句换行超过一行，则将结束括号单独放置一行
  dangle_parens = True

  # If the trailing parenthesis must be 'dangled' on its on line, then align it...
  # 当结束括号需要悬挂时，对齐方式（prefix: 语句开头，prefix-indent: 加一级缩进，child: 参数列）
  dangle_align = 'prefix'

  # If the statement spelling length (including space and parenthesis) is...
  # 若语句长度（含空格和括号）小于该值，则拒绝嵌套布局
  min_prefix_chars = 10

  # If the statement spelling length (including space and parenthesis) is larger...
  # 若语句长度（含空格和括号）超过tab宽度指定值，则拒绝非嵌套布局
  max_prefix_chars = 20

  # If a candidate layout is wrapped horizontally but it exceeds this many...
  # 若候选水平布局超过指定行数，则拒绝该布局
  max_lines_hwrap = 6

  # What style line endings to use in the output.
  # 输出时使用的换行符类型（unix/windows）
  line_ending = 'unix'

  # Format command names consistently as 'lower' or 'upper' case
  # 将命令名称统一格式化为'lower'或'upper'大小写
  command_case = 'lower'

  # Format keywords consistently as 'lower' or 'upper' case
  # 将关键字统一格式化为'lower'或'upper'大小写
  keyword_case = 'upper'

  # A list of command names which should always be wrapped
  # 始终需要换行的命令名称列表
  always_wrap = []

  # If true, the argument lists which are known to be sortable will be sorted...
  # 若为True，可排序的参数列表将按字典序排序
  enable_sort = True

  # If true, the parsers may infer whether or not an argument list is sortable...
  # 若为True，解析器可推断参数列表是否可排序
  autosort = False

  # By default, if cmake-format cannot successfully fit everything into the...
  # 默认情况下，若无法适配到指定行宽，会应用最后尝试的布局。若为True则报错不输出
  require_valid_layout = False

  # A dictionary mapping layout nodes to a list of wrap decisions. See the...
  # 布局节点到换行决策的字典映射（详见文档）
  layout_passes = {}

# ------------------------------------------------
# Options affecting comment reflow and formatting.
# ------------------------------------------------
# 影响注释重排和格式化的选项
with section("markup"):

  # What character to use for bulleted lists
  # 无序列表使用的符号字符
  bullet_char = '*'

  # What character to use as punctuation after numerals in an enumerated list
  # 有序列表数字后的标点符号
  enum_char = '.'  

  # If comment markup is enabled, don't reflow the first comment block in each...
  # 若启用注释标记，保留每个列表文件的第一个注释块格式
  first_comment_is_literal = False

  # If comment markup is enabled, don't reflow any comment block which matches...
  # 若匹配该正则模式则不重排注释（默认禁用）
  literal_comment_pattern = None

  # Regular expression to match preformat fences in comments default=...
  # 匹配注释中预格式化围栏的正则表达式（默认值）
  fence_pattern = '^\\s*([`~]{3}[`~]*)(.*)$'

  # Regular expression to match rulers in comments default=...
  # 匹配注释中分隔线的正则表达式（默认值）
  ruler_pattern = '^\\s*[^\\w\\s]{3}.*[^\\w\\s]{3}$'

  # If a comment line matches starts with this pattern then it is explicitly a...
  # 若注释行以此模式开头，则视为前导参数的尾注（默认#<）
  explicit_trailing_pattern = '#<'

  # If a comment line starts with at least this many consecutive hash...
  # 若注释行以至少该数量的连续#开头，则保留其格式
  hashruler_min_length = 10

  # If true, then insert a space between the first hash char and remaining hash...
  # 若为True，在哈希分隔线首字符后插入空格并标准化长度
  canonicalize_hashrulers = True

  # enable comment markup parsing and reflow
  # 启用注释标记解析和重排
  enable_markup = True

# ----------------------------
# Options affecting the linter
# ----------------------------
# 影响代码检查器的选项
with section("lint"):

  # a list of lint codes to disable
  # 需要禁用的lint代码列表
  disabled_codes = []

  # regular expression pattern describing valid function names
  # 有效函数名的正则表达式模式
  function_pattern = '[0-9a-z_]+'

  # regular expression pattern describing valid macro names
  # 有效宏名的正则表达式模式
  macro_pattern = '[0-9A-Z_]+'

  # regular expression pattern describing valid names for variables with global...
  # 全局变量命名正则表达式模式
  global_var_pattern = '[A-Z][0-9A-Z_]+'

  # regular expression pattern describing valid names for variables with global...
  # 内部全局变量命名正则表达式模式
  internal_var_pattern = '_[A-Z][0-9A-Z_]+'

  # regular expression pattern describing valid names for variables with local...
  # 局部变量命名正则表达式模式
  local_var_pattern = '[a-z][a-z0-9_]+'

  # regular expression pattern describing valid names for privatedirectory...
  # 私有目录变量命名正则表达式模式
  private_var_pattern = '_[0-9a-z_]+'

  # regular expression pattern describing valid names for public directory...
  # 公共目录变量命名正则表达式模式
  public_var_pattern = '[A-Z][0-9A-Z_]+'

  # regular expression pattern describing valid names for function/macro...
  # 函数/宏参数和循环变量命名正则表达式模式
  argument_var_pattern = '[a-z][a-z0-9_]+'

  # regular expression pattern describing valid names for keywords used in...
  # 函数/宏中关键字命名正则表达式模式
  keyword_pattern = '[A-Z][0-9A-Z_]+'

  # In the heuristic for C0201, how many conditionals to match within a loop in...
  # 在C0201启发式算法中，循环内匹配多少条件语句后视为解析器
  max_conditionals_custom_parser = 2

  # Require at least this many newlines between statements
  # 语句间至少需要的空行数
  min_statement_spacing = 1

  # Require no more than this many newlines between statements
  # 语句间最多允许的空行数
  max_statement_spacing = 2
  max_returns = 6
  max_branches = 12
  max_arguments = 5
  max_localvars = 15
  max_statements = 50

# -------------------------------
# Options affecting file encoding
# -------------------------------
# 影响文件编码的选项
with section("encode"):

  # If true, emit the unicode byte-order mark (BOM) at the start of the file
  # 若为True，在文件开头写入Unicode字节顺序标记(BOM)
  emit_byteorder_mark = False

  # Specify the encoding of the input file. Defaults to utf-8
  # 指定输入文件的编码（默认utf-8）
  input_encoding = 'utf-8'

  # Specify the encoding of the output file. Defaults to utf-8. Note that cmake...
  # 指定输出文件的编码（默认utf-8）。注意cmake仅支持utf-8
  output_encoding = 'utf-8'

# -------------------------------------
# Miscellaneous configurations options.
# -------------------------------------
# 其他配置选项
with section("misc"):

  # A dictionary containing any per-command configuration overrides. Currently...
  # 包含特定命令配置覆盖的字典。目前仅支持command_case
  per_command = {}