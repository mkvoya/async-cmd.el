;;; test-async-cmd.el --- Tests for async-cmd.el (buffer output) -*- lexical-binding: t -*-

(require 'ert)
(require 'async-cmd)

;;; 测试简单 echo 命令
(ert-deftest async-cmd-basic-echo ()
  "Test running a simple echo command."
  (let ((id (async-cmd-start "/bin/echo" '("Hello Test"))))
    ;; 等待进程结束 (最多 2 秒)
    (let ((timeout 20))
      (while (and (> timeout 0) (not (async-cmd-finished-p id)))
        (accept-process-output nil 0.1)
        (setq timeout (1- timeout))))
    (should (async-cmd-finished-p id))
    (should (= 0 (async-cmd-exit-status id)))
    (let ((buf (async-cmd-output-buffer id)))
      (with-current-buffer buf
        (goto-char (point-min))
        (should (search-forward "Hello Test" nil t))))
    (async-cmd-kill-and-cleanup id)))

;;; 测试 callback
(ert-deftest async-cmd-callback ()
  "Test that callback is invoked after process finishes."
  (let ((cb-called nil))
    (let ((id
           (async-cmd-start "/bin/echo" '("Callback Works")
                            (lambda (id status buf)
                              (setq cb-called (list id status buf))))))
      ;; 等待
      (let ((timeout 20))
        (while (and (> timeout 0) (not (async-cmd-finished-p id)))
          (accept-process-output nil 0.1)
          (setq timeout (1- timeout))))
      (should cb-called)
      (pcase-let ((`(,cid ,status ,buf) cb-called))
        (should (stringp cid))
        (should (= status 0))
        (with-current-buffer buf
          (goto-char (point-min))
          (should (search-forward "Callback Works" nil t)))))
    ;; cleanup
    (maphash (lambda (k _v) (async-cmd-kill-and-cleanup k)) async-cmd--table)))

;;; 测试 cleanup
(ert-deftest async-cmd-cleanup ()
  "Test cleanup removes buffer and id."
  (let ((id (async-cmd-start "/bin/echo" '("Bye"))))
    (let ((timeout 20))
      (while (and (> timeout 0) (not (async-cmd-finished-p id)))
        (accept-process-output nil 0.1)
        (setq timeout (1- timeout))))
    (let ((buf (async-cmd-output-buffer id)))
      (should (buffer-live-p buf))
      (async-cmd-kill-and-cleanup id)
      (should-not (gethash id async-cmd--table))
      (should-not (buffer-live-p buf)))))

(provide 'test-async-cmd)
;;; test-async-cmd.el ends here
