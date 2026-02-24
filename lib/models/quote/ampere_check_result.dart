enum AmpereCheckResult {
  ok, // 可以正常加入
  warning, // 超過80%，警告但允許加入
  blocked, // 超過最大限制，不允許加入
}
