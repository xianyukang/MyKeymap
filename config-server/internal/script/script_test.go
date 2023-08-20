package script

import "testing"

func TestSortActions(t *testing.T) {
	a := Action{WindowGroupID: 0, Comment: "item1"}
	b := Action{WindowGroupID: 1, Comment: "item2"}
	c := Action{WindowGroupID: 0, Comment: "item3"}
	s := []Action{a, b, c}
	ss := sortActions(s)
	assertEqual(t, ss[0], b)
	assertEqual(t, ss[1], a)
	assertEqual(t, ss[2], c)
}

func assertEqual[T comparable](t *testing.T, a, b T) {
	t.Helper()
	if a != b {
		t.Errorf("%v != %v", a, b)
	}
}
