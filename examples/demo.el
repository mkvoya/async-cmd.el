;;; demo.el --- Example usage of async-cmd.el -*- lexical-binding: t; -*-

(require 'async-cmd)

(defun demo-run-echo ()
  "Run echo command asynchronously and print result."
  (interactive)
  (let ((id
         (async-cmd-start
          "/bin/echo" '("Hello from async-cmd!")
          (lambda (id status buf)
            (message "Process %s finished with status %s" id status)
            (when (buffer-live-p buf)
              (with-current-buffer buf
                (message "Output:\n%s" (buffer-string))))))))
    (message "Started process with id: %s" id)))

(provide 'demo)
;;; demo.el ends here
