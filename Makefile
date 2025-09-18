test:
	emacs -Q --batch -L . -l tests/test-async-cmd.el -f ert-run-tests-batch-and-exit
