# std 工具（QoolCommon）

## `std::string qoolui::tools::generate_random_string(size_t length, std::optional<unsigned> seed, std::optional<std::string> chars)`

生成指定长度的随机字符串。

- `length` 目标长度，默认 5。
- `seed` 随机种子；缺省时以系统时钟计数为种子
  （每次调用种子不同，结果不可复现）。
- `chars` 取样字符集；缺省时使用内置的去除易混淆字符
  （如 I/L/O/U/V 及小写 i/l/o/u/v）的字符集。
  显式传入空字符集时无法取样，直接返回空串——避免
  分布上下界倒置的未定义行为。

- 注意：取样上限必须是字符数（charset.size()-1），不能用
  sizeof(charset)：sizeof(std::string) 是对象大小而非字符串长度，
  会越界读取对象内存。
