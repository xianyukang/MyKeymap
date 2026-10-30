//go:build !windows

package midi

// OutputPortNames 在非 Windows 平台上不支持, 返回空列表。
func OutputPortNames() ([]string, error) {
	return []string{}, nil
}
