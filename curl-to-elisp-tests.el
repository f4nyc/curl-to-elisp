;;; curl-to-elisp-tests.el --- Tests                 -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Tests for curl-to-elisp.el

;;; Code:

(require 'ert)
(require 'curl-to-elisp)

(ert-deftest curl-to-elisp--tokenize ()
  "Test the curl command parser."
  (should (equal (curl-to-elisp--tokenize "curl -I example.com")
                 '("-I" "example.com")))
  ;; absolute path
  (should (equal (curl-to-elisp--tokenize "/usr/bin/curl -I example.com")
                 '("-I" "example.com")))
  ;; pipeline
  (should (equal (curl-to-elisp--tokenize "echo hello | curl -d @- localhost:7777")
                 '("-d" "@-" "localhost:7777")))
  ;; quote
  (should (equal (curl-to-elisp--tokenize "curl -d 'hello world' -d \"bye world\" localhost:7777")
                 '("-d" "hello world" "-d" "bye world" "localhost:7777")))
  ;; escape
  (should (equal (curl-to-elisp--tokenize "curl -d hello\\ world localhost:7777")
                 '("-d" "hello world" "localhost:7777")))
  ;; multiple lines
  (should (equal (curl-to-elisp--tokenize
                  "curl -v \\
-d hello \\
  example.com")
                 '("-v" "-d" "hello" "example.com"))))

(ert-deftest curl-to-elisp ()
  (should (equal (curl-to-elisp "curl example.com")
                 '(url-retrieve-synchronously "http://example.com")))

  (should (equal (curl-to-elisp "curl -I example.com")
                 '(let ((url-request-method "HEAD"))
                    (url-retrieve-synchronously "http://example.com"))))

  (should (equal (curl-to-elisp "curl -d 'hello world' example.com")
                 '(let ((url-request-method "POST")
                        (url-request-extra-headers
                         '(("Content-Type" . "application/x-www-form-urlencoded")))
                        (url-request-data "hello world"))
                    (url-retrieve-synchronously "http://example.com"))))

  (should (equal (curl-to-elisp "curl -d hello -d world example.com")
                 '(let ((url-request-method "POST")
                        (url-request-extra-headers
                         '(("Content-Type" . "application/x-www-form-urlencoded")))
                        (url-request-data "hello&world"))
                    (url-retrieve-synchronously "http://example.com"))))

  (should (string-match-p
           "Referer"
           (prin1-to-string
            (curl-to-elisp "curl -v --referer http://gnu.org example.com"))))

  (should (equal (curl-to-elisp "curl example.com -u demo:p@55w0rd")
                 '(let ((url-request-extra-headers
                         '(("Authorization" . "Basic ZGVtbzpwQDU1dzByZA=="))))
                    (url-retrieve-synchronously "http://example.com")))))

(provide 'curl-to-elisp-tests)
;;; curl-to-elisp-tests.el ends here
