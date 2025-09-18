;;; async-cmd.el --- Simple async command manager with buffer output -*- lexical-binding: t -*-

(require 'cl-lib)

(defvar async-cmd--table (make-hash-table :test 'equal)
  "Hash table mapping id -> plist with keys:
:process (the process object)
:finished (t/nil)
:exit-status (integer or nil)
:callback (function or nil)
:buffer (buffer object for output)")

(defvar async-cmd--counter 0
  "Counter for generating unique ids.")

(defun async-cmd--gen-id ()
  "Generate a new unique identifier string."
  (format "async-cmd-%d-%d" (float-time) (cl-incf async-cmd--counter)))

;;;###autoload
(defun async-cmd-start (program args &optional callback)
  "Run PROGRAM with ARGS asynchronously.
Output is captured into a buffer and returned via identifier.

If CALLBACK is non-nil, it will be called when the process finishes as
  (funcall CALLBACK id exit-status buffer)."
  (interactive
   (list (read-file-name "Program: ")
         (split-string (read-string "Args: ") " " t)))
  (let* ((id (async-cmd--gen-id))
         (buf (generate-new-buffer (format "*async-cmd-%s*" id)))
         (proc (make-process
                :name (format "%s-proc" id)
                :command (cons program args)
                :buffer buf
                :noquery t
                :sentinel
                (lambda (p _event)
                  (let ((info (gethash id async-cmd--table))
                        (exit (process-exit-status p)))
                    (when info
                      (plist-put info :finished t)
                      (plist-put info :exit-status exit)
                      (puthash id info async-cmd--table)
                      (when-let* ((cb (plist-get info :callback)))
                        (funcall cb id exit buf))))))))
    (puthash id (list :process proc
                      :buffer buf
                      :finished nil
                      :exit-status nil
                      :callback callback)
             async-cmd--table)
    id))

;;;###autoload
(defun async-cmd-finished-p (id)
  "Return non-nil if process for ID finished."
  (let ((info (gethash id async-cmd--table)))
    (unless info (error "Unknown id: %s" id))
    (plist-get info :finished)))

;;;###autoload
(defun async-cmd-exit-status (id)
  "Return exit status for ID, or nil if not finished."
  (let ((info (gethash id async-cmd--table)))
    (unless info (error "Unknown id: %s" id))
    (plist-get info :exit-status)))

;;;###autoload
(defun async-cmd-output-buffer (id)
  "Return the buffer capturing output for ID."
  (let ((info (gethash id async-cmd--table)))
    (unless info (error "Unknown id: %s" id))
    (plist-get info :buffer)))

;;;###autoload
(defun async-cmd-kill-and-cleanup (id)
  "Kill process and remove resources for ID."
  (let ((info (gethash id async-cmd--table)))
    (unless info (error "Unknown id: %s" id))
    (let ((proc (plist-get info :process))
          (buf (plist-get info :buffer)))
      (when (process-live-p proc)
        (ignore-errors (kill-process proc)))
      (when (buffer-live-p buf)
        (kill-buffer buf))
      (remhash id async-cmd--table)
      t)))

(provide 'async-cmd)
;;; async-cmd.el ends here
