#lang slideshow

(require plot/pict
         pict/color
         slideshow/code
         slideshow/text
         slideshow/repl
         slideshow/latex)

(module+ slideshow

  (setup-local-latex-cache)
  (latex-debug? #t)
  (add-preamble #<<latex
\usepackage{bm}
\usepackage{amsmath}
\usepackage{euler}
\usepackage{xcolor}
\newcommand{\dd}[2]{\tfrac{\mathsf{d}#1}{\mathsf{d}#2}}
latex
                )
  (define racket-logo (bitmap "images/racket-logo.png"))
  (define λ-days-logo (bitmap "images/lambda-days-logo.png"))
  (define frac-client-h (blank (* 0.15 client-h) (* 0.15 client-h)))

  (define (stacked-rect #:color color . picts)
    (λ ([fit-width (blank 0)])
      (define stacked (apply vc-append picts))
      (define rect
        (scale-to-fit (cellophane
                       (filled-rectangle 1 1
                                         #:color color
                                         #:draw-border? #f)
                       0.1)
                      (vc-append stacked (scale-to-fit fit-width
                                                       (pict-width fit-width)
                                                       0
                                                       #:mode 'distort))
                      #:mode 'distort))

      (code-align (cc-superimpose rect stacked))))

  (define (replace-within outer-pict outer-opacity
                          inner-pict [replacement-pict inner-pict])
    (let-values ([(dx dy) (lt-find outer-pict inner-pict)])
      (panorama
       (pin-over (cellophane outer-pict outer-opacity)
                 dx dy
                 replacement-pict))))

  (define-syntax-rule (D a) (hc-append (code d) (code a)))

  (plot-font-size 24)
  (line-width 2.5)
  (plot-width (inexact->exact (round (* 0.65 client-w))))
  (plot-height (inexact->exact (round (* 0.8 client-h))))
  (plot-font-family 'default)

  ;; ----------------------------------------

  {slide
   (titlet "A functional tour of automatic differentiation")
   (titlet "with Racket")
   (t "Oliver Strickson")
   (t "2020-02-14")
   (t "Kraków")

   (hc-append
    (scale-to-fit racket-logo frac-client-h)
    (blank (* 0.3 client-w) 0)
    (scale-to-fit λ-days-logo frac-client-h #:mode 'preserve/max))}

  ;; ----------------------------------------

  {slide
   (hc-append
    (vl-append
     (t "Oliver Strickson")
     (t "Research Software Engineer")
     (t "Research Engineering Group"))
    (blank 200 0)
    (scale-to-fit (bitmap "images/turing-logo.png")
                  (* 0.3 client-w) (* 0.3 client-h))
    )

   (vl-append
    (scale-to-fit (bitmap "images/british-library.jpg")
                  (* 0.9 client-w) (* 0.5 client-h))
    (small (t "Photo credit: https://commons.wikimedia.org/wiki/User:Patche99z")))
   }

  ;; ----------------------------------------

;  {slide
;   #:title "Introduction"
;   }

  ;; ----------------------------------------

  {slide
   #:title "Overview"
   (item "Differentiation")
   (item "Automatic differentiation algorithm")
   (item "Implementation by program tracing")
   (item "Implementation by program transformation")
   (item "Local program transformation: Dual numbers")
   ;; (item "Local program transformation: Continuations")
   (item "Resources")
   }

  ;; ----------------------------------------

  {slide
   #:title "Differentiation"
   'next
   (t "The best linear approximation to a function about a point (if it exists)")
   'next
   (para "Function" ($"f") "or" (code f))
   (para "Derivative" ($"Df") "or" (code (D f)))
   }


  {slide
   (plot (list
          (function (λ (x) (sqrt x)) 0 10
                    ; #:label "(sqrt x)"
                    #:color "SkyBlue")
          (function (λ (x) (+ (* 0.25 x) 1)) 0 10
                    ; #:label "(* ((D sqrt) 4.0) x)"
                    #:color "DarkViolet")))}

  {slide
   #:title "Differentiation"

   (para "function" ($"f(x)"))
   (para "find" ($"a") "with")
   (para ($"f(x) - f(x_0) \\approx a\\,(x - x_0)"))
   'next
   (para ($"f(x) - f(x_0) = a\\,(x - x_0) + o(x - x_0)"))
   'next
   (para ($$"f(x) - f(x_0) = \\textcolor{red}{Df(x_0)} \\, (x - x_0) + o(x - x_0)"))
   }

  {slide
   #:title "Differentiation"
   (para "function" ($"f(x, y)"))
   (para "find" ($"a, b") "with")
   (para ($"f(x, y) - f(x_0, y_0) \\approx a\\,(x - x_0) + b\\,(y - y_0)"))
   'next
   (para ($$"f(x, y) - f(x_0, y_0) \\approx \\textcolor{red}{D_0f(x_0, y_0)} \\, (x - x_0) + \\textcolor{red}{D_1f(x_0, y_0)} \\, (y - y_0)"))
   'next
   ;; partial derivs
   (para "Partial derivative" ($"D_if") "or" (code (partial i f)))
   'next
   (para ($"Df(x,y) = (D_0f(x,y), D_1f(x,y))"))

   ;; TODO structures?
   }

  {slide
   (code
    (define ((partial i f) . xs)
      (case f
        (code:comment "...")
        [(exp)      (case i
                      [(0)   (exp (first xs))]
                      [else  (err)])]
        (code:comment "...")

        [else (err)])))}

  {slide
   (code
    (define ((partial i f) . xs)
      (case f
        (code:comment "...")
        [(*)        (case i
                      [(0)   (list-ref xs 1)]
                      [(1)   (list-ref xs 0)]
                      [else  (err)])]
        (code:comment "...")

        [else (err)])))}

  {slide
   #:title "Composition"
   'next

   ;; write this in maths too

   (code
    ([D (compose g f)] x)
    = (* ([D g] (f x))
         ([D f] x)))

   ;; 'next
   ;; (para "really")
   ;; (code (compose ([D g] (f x))
   ;;                ([D f] x)))
   ;; (para "composition of linear maps => product of coefficients")
   }

  {slide
   #:title "Composition"
   (para ($"f(x,y) = g(u(x,y), v(x,y))"))
   (para
    (lt (string-join
         '("\\begin{equation*}"
           "\\begin{split}"
           "Df(x,y) =\\\\"
           "& D_0g(u(x,y),v(x,y)) \\, Du(x,y)\\\\"
           " +\\; &D_1g(u(x,y),v(x,y)) \\, Dv(x,y)"
           "\\end{split}"
           "\\end{equation*}"))))
   }

  (define f-graph
    (scale-to-fit (bitmap "images/f.png") (* 0.6 client-w) (* 0.6 client-h)))

  {slide
   #:title "Arithmetic expressions"
   (code
    (define (f a b)
      (+ (* a a) (* a b))))
   'next
   (ht-append
    f-graph
    (blank (* 0.1 client-w) 0)
    (vc-append
     (blank 0 30)
     (code c ← (* a a)
           d ← (* a b)
           e ← (+ c d))))
   }

  (define (make-slide-fwd-ad n
                             #:init-option [init-option 0]
                             #:box-init? [box-init? #f])
    (define final-expr
      (case init-option
        [(0) ($"D_0f(a,b) = \\dd{e}{r}")]
        [(1) ($"D_1f(a,b) = \\dd{e}{r}")]))

    (define init-expr
      (case init-option
        [(0) (vl-append (current-line-sep)
                        (para ($"\\dd{a}{r} = 1") #:fill? #f)
                        (para ($"\\dd{b}{r} = 0") #:fill? #f))]
        [(1) (vl-append (current-line-sep)
                        (para ($"\\dd{a}{r} = 0") #:fill? #f)
                        (para ($"\\dd{b}{r} = 1") #:fill? #f))]))

    (define (eqn-lines n)
      (parameterize ([current-line-sep 20])
        (apply
         para
         (take
          (list
           (vc-append
            (blank 0 20)
            ((if box-init? frame identity) init-expr))
           (para ($"\\dd{c}{r} = D_0(*)(a,a)\\dd{a}{r} + D_1(*)(a,a)\\dd{a}{r}"))
           (para ($"\\dd{d}{r} = D_0(*)(a,b)\\dd{a}{r} + D_1(*)(a,b)\\dd{b}{r}"))
           (para ($"\\dd{e}{r} = D_0(+)(c,d)\\dd{c}{r} + D_1(+)(c,d)\\dd{d}{r}"))
           final-expr
           (para (bt "Forward mode") #:align 'center))
          n))))

    {slide
     #:title "Automatic differentiation"
     (para "Compute" ($"Df(a,b)"))
     (ht-append
      f-graph
      (blank 20 (pict-height (eqn-lines 6)))
      (eqn-lines n))})

  (make-slide-fwd-ad 0)
  (make-slide-fwd-ad 1)
  (make-slide-fwd-ad 2)
  (make-slide-fwd-ad 3)
  (make-slide-fwd-ad 4)
  (make-slide-fwd-ad 5)
  (make-slide-fwd-ad 5 #:box-init? #t)
  (make-slide-fwd-ad 5 #:box-init? #t #:init-option 1)
  (make-slide-fwd-ad 6 #:init-option 1)

  {slide
   (para "Often write" (code #,(D x)) "instead of" ($"\\dd{x}{r}"))
   (para "Known as" (it "perturbation variables"))
   }

  (define fwd-mode-graph
    (scale-to-fit (bitmap "images/fm.png")
                  (* 0.45 client-w) (* 0.6 client-h)))

  (define fwd-mode-graph-2
    (scale-to-fit (bitmap "images/fm2.png")
                  (* 0.45 client-w) (* 0.8 client-h)))

  (define rev-mode-graph
    (scale-to-fit (bitmap "images/rm.png")
                  (* 0.5 client-w) (* 0.7 client-h)))

  (define rev-mode-graph-2
    (scale-to-fit (bitmap "images/rm2.png")
                  (* 0.5 client-w) (* 0.8 client-h)))

  {slide
   (hc-append
    (scale-to-fit (bitmap "images/orig.png")
                  (* 0.45 client-w) (* 0.5 client-h))
    (blank (* 0.05 client-w))
    (arrow 30 0)
    (blank (* 0.05 client-w))
    (cc-superimpose fwd-mode-graph (ghost fwd-mode-graph-2)))
   }

  {slide
   (hc-append
    (scale-to-fit (bitmap "images/orig.png")
                  (* 0.45 client-w) (* 0.5 client-h))
    (blank (* 0.05 client-w))
    (arrow 30 0)
    (blank (* 0.05 client-w))
    (cc-superimpose fwd-mode-graph-2 (ghost fwd-mode-graph)))
   }

  (define (make-slide-rev-ad n)

    (define (eqn-lines n)
      (parameterize ([current-line-sep 20])
        (apply
         para
         (take
          (list
           (para ($"\\dd{s}{e} = 1"))
           (para ($"\\dd{s}{d} = D_1(+)(c,d)\\dd{s}{e}"))
           (para ($"\\dd{s}{c} = D_0(+)(c,d)\\dd{s}{e}"))
           (para ($"\\dd{s}{b} = D_1(*)(a,b)\\dd{s}{d}"))
           (para (lt "\\begin{equation*}
\\begin{split}
\\dd{s}{a} = D_0(*)(a,&a)\\dd{s}{c} + D_1(*)(a,a)\\dd{s}{c}\\\\
&+\\; D_0(*)(a,b)\\dd{s}{d}
\\end{split}
\\end{equation*}
"))
           (para ($"Df(a,b) = \\left(\\dd{s}{a}, \\dd{s}{b}\\right)"))
           (para (bt "Reverse mode") #:align 'center))
          n))))

    {slide
     #:title "Automatic differentiation"

     (para "Compute" ($"Df(a,b)"))
     (ht-append
      f-graph
      (blank 20 (pict-height (eqn-lines 7)))
      (eqn-lines n))

     })

  (make-slide-rev-ad 0)
  (make-slide-rev-ad 1)
  (make-slide-rev-ad 2)
  (make-slide-rev-ad 3)
  (make-slide-rev-ad 4)
  (make-slide-rev-ad 5)
  (make-slide-rev-ad 6)
  (make-slide-rev-ad 7)

  {slide
   (para "Often write" (code Ax) "instead of" ($"\\dd{s}{x}"))
   (para "Known as" (it "sensitivity variables") "or" (it "adjoints"))
   }

  {slide
   (hc-append
    (scale-to-fit (bitmap "images/orig.png")
                  (* 0.45 client-w) (* 0.5 client-h))
    (blank (* 0.05 client-w))
    (arrow 30 0)
    (blank (* 0.05 client-w))
    (cc-superimpose rev-mode-graph (ghost rev-mode-graph-2)))
   }

  {slide
   (hc-append
    (scale-to-fit (bitmap "images/orig.png")
                  (* 0.45 client-w) (* 0.5 client-h))
    (blank (* 0.05 client-w))
    (arrow 30 0)
    (blank (* 0.05 client-w))
    (cc-superimpose rev-mode-graph-2 (ghost rev-mode-graph)))
   }

  {slide
   (para "Idea: every value returned by a program was determined from a"
         "particular (dynamic) computational graph.")
   (para "Differentiate" (it "that"))
   }

  ;; {slide
  ;;  #:title "Example: sum of squares"

  ;;  (code (define (sum-squares a b)
  ;;          (+ (* a a) (* b b))))

  ;;  (para "Find D" (tt "sum-squares") #:align 'center)
  ;;  }

  ;; {slide
  ;;  (t "Explicit assignments for each operation:")

  ;;  (vc-append
  ;;   (para (code a) "and" (code b) "given;" #:align 'center)
  ;;   (code c ← (* a a)
  ;;         d ← (* b b)
  ;;         e ← (+ c d)))
  ;;  }

  ;; (define (Dsum-squares a Da b Db) (+ (* 2 Da a) (* 2 Db b)))

  ;; {slide
  ;;  #:title "Example: sum of squares"

  ;;  (code c ← (* a a)
  ;;        d ← (* b b)
  ;;        e ← (+ c d))
  ;;  'next
  ;;  (code
  ;;   #,(D c) ← (+ (* a #,(D a)) (* #,(D a) a))
  ;;   #,(D d) ← (+ (* b #,(D b)) (* #,(D b) b))
  ;;   #,(D e) ← (+ #,(D c) #,(D d)))

  ;;  ;; result is a linear function of a and b to a single number
  ;;  'next
  ;;  'alts
  ;;  (list
  ;;   (list
  ;;    (code
  ;;     #,(D a) ← 1
  ;;     #,(D b) ← 0))

  ;;   (list
  ;;    (code
  ;;     #,(D a) ← 0
  ;;     #,(D b) ← 1
  ;;     ))

  ;;   (list
  ;;    (code
  ;;     #,(D a) ← 1
  ;;     #,(D b) ← 0)
  ;;    (code a ← 3
  ;;          b ← 4)
  ;;    (code (6 #,(ghost (code 8)))))

  ;;   (list
  ;;    (code
  ;;     #,(D a) ← 0
  ;;     #,(D b) ← 1)
  ;;    (code a ← 3
  ;;          b ← 4)
  ;;    (code (6 8))))

  ;;  }

  ;; ;; dw/dw

  ;; ;; dw/dy


  ;; ;; reverse mode
  ;; {slide
  ;;  #:title "Example: sum of squares"

  ;;  (code c ← (* a a)
  ;;        d ← (* b b)
  ;;        e ← (+ c d))
  ;;  'next
  ;;  ;; (code
  ;;  ;;  #,(A d) ← #,(A e
  ;;  ;;  #,(A c) ←
  ;;  ;;  #,(A b) ←
  ;;  ;;  #,(A a) ←

  ;;  }

  ;; ;; more examples ...


  ;; ;; forward and backwards ...


  ;; ;; more general explanation ...



  {slide
   #:title "Tracing program execution"

   (para "We want to make a particular type of trace, which is:")
   (item (para "flat"))
   (item (para "topologically sorted"))
   (item (para "contains only" (it "primitive operations")))
   }

  ;; {slide
  ;;  (code (define (sum-squares a b)
  ;;          (+ (* a a) (* b b))))
  ;;  }

  {slide
   (para "  " (code (sum-squares x y)))
   (para "=>" (code (sum-squares 3 4)))
   (para "=>" (code 25))
   }

  (define x (stacked-rect #:color "red" (t ".") (t ".")  (code 3)))
  (define y (stacked-rect #:color "blue" (t ".") (t ".") (code 4)))
  (define z (stacked-rect #:color "yellow" (t ".") (t ".") (code 25)))

  {slide
   ;; (para "  " (code (sum-squares x y)))
   ;; (para "=>" (code (sum-squares #,(code-align (frame (vc-append (code 1) (code 2)))) #,(code-align (frame (vc-append (code 1) (code 2)))))))
   ;; (para "=>" (code #,(frame (code 5))))

   (para "   " (code (sum-squares x y)))

   (para "=>" (code (sum-squares #,(frame (x)) #,(frame (y)))))
   (para "=>" (code-align (frame (vc-append
                                  (x (z))
                                  (y (z))
                                  (z)))))
   }

  (define x* (stacked-rect #:color "red"
                           (tt "%1 | (constant 3)  |  3")))

  (define y* (stacked-rect #:color "blue"
                           (tt "%2 | (constant 4)  |  4")))

  (define z* (stacked-rect #:color "yellow"
                           (tt "%3 | (app * %1 %1) |  9")
                           (tt "%4 | (app * %2 %2) | 16")
                           (tt "%5 | (app + %3 %4) | 25")))

  {slide
   ;; (para "  " (code (sum-squares x y)))
   ;; (para "=>" (code (sum-squares #,(code-align (frame (vc-append (code 1) (code 2)))) #,(code-align (frame (vc-append (code 1) (code 2)))))))
   ;; (para "=>" (code #,(frame (code 5))))

   (para (code x))
   (para "=>" (code 3) ", as " (frame (x*)))

   (para (code y))
   (para "=>" (code 4) ", as " (frame (y*)))

   (para (code (sum-squares x y)))

   ;(para "=>" (code (sum-squares #,(frame x*) #,(frame y*))))
   (para "=>" (code 25) ", as " (code-align (frame (vc-append (x*) (y*) (z*)))))

   }

  {slide
   (para "Let's make a little language that does this...")
   }

  {slide
   #:title "What is a language?"
   (para "Functions")
   (para "Other special forms (" (code if) "," (code λ) "," (code define)
         ", " (code require) ", ... )")
   (para "Evaluation model")
   (para "Literal data")
   (para "Syntax")
   }
  ;; e.g. simple 'language' could just involve providing some functions
  ;; ... all the way to something with a custom reader

  {slide
   #:title "assignments"
   (code
    (struct assignment (id expr val)
      #:transparent
      #:guard (struct-guard/c symbol? expr? any/c)))

   'next
   (code assignment?
         assignment-id
         assignment-expr
         assignment-val)

   'next
   (code
    (define (expr? e)
      (match e
        [(list 'constant _) #t]
        [(list 'app (? symbol? _) ..1) #t]
        [_ #f])))
   }

  {slide
   #:title "trace"
   (code (struct trace (assignments)))

   'next
   (code (trace-add tr assgn)
         (trace-append trs ...))

   'next
   (para (it "top") "of a trace is the most recent assignment")
   (code (top tr))

   'next
   (code
    (top-val tr)
    (top-id tr)
    (top-expr tr))


   }

  {slide
   #:title "trace-lang functions"
   (code
    (define (+& a b)
      (trace-add
       (trace-append a b)
       (make-assignment
        #:expr (list 'app '+ (top-id a) (top-id b))
        #:val  (+ (top-val a) (top-val b))))))
   }

  {slide
   #:title "trace-lang functions"
   (code
    (define (*& a b)
      (trace-add
       (trace-append a b)
       (make-assignment
        #:expr (list 'app '* (top-id a) (top-id b))
        #:val  (* (top-val a) (top-val b))))))
   }

  {slide
   #:title "trace-lang functions"
   (code
    (define (exp& x)
      (trace-add
       x
       (make-assignment
        #:expr (list 'app 'exp (top-id x))
        #:val  (exp (top-val x))))))
   }

  ;; ----------------------------------------

  (define def-traced-f
    (code
     (define (f a ...)
       (trace-add
        (trace-append a ...)
        (make-assignment
         #:expr (list 'app f-name (top-id a) ...)
         #:val  (let ([a (top-val a)] ...)
                  body ...))))))

  (define def-traced-f-stx
    (ht-append (codeblock-pict "#'") def-traced-f))

  (define def-traced-macro-full
    (code
     (define-syntax (define-traced-primitive stx)
       (syntax-case stx ()
         [(_ (f a ...) f-name
             body ...)
          #,(cellophane def-traced-f-stx 0.0)]))))

  (define (place-over-trace-macro p opacity)
    (let-values ([(dx dy)
                  (lt-find def-traced-macro-full def-traced-f-stx)])
      (panorama
       (pin-over (cellophane def-traced-macro-full opacity)
                 dx dy
                 p))))

  {slide (place-over-trace-macro (hc-append (ghost (tt "#'")) def-traced-f)
                                 0.0)}

  {slide (place-over-trace-macro def-traced-f-stx
                                 0.0)}

  {slide (place-over-trace-macro (cellophane def-traced-f-stx 0.2)
                                 1.0)}

  {slide (place-over-trace-macro def-traced-f-stx
                                 1.0)}

  {slide
   #:title "trace-lang functions"
   (code
    (define-traced-primitive (+& a b) '+
      (+ a b))
    (define-traced-primitive (*& a b) '*
      (* a b))
    (code:comment "...")
    (define-traced-primitive (<& a b) '<
      (< a b))
    (code:comment "...")
    (define-traced-primitive (cons& a b) 'cons
      (cons a b))
    (code:comment "..."))}

  {slide
   (vl-append
    (tt "#lang racket")
    (code
     (code:comment "...")
     (provide (rename-out [+& +]
                          [*& *]
                          [exp& exp]
                          ...))
     (code:comment "...")))

    }

  {slide
   #:title "rename-out"
   (item "Useful for modifying behaviour of an existing language")
   (item "Can refer to the original binding in the defining module")
   (item "External interface has the new binding")
   }

  {slide
   #:title "Interposition points"
   ;; #%datum, #%app etc

   ;; one thing we could do is permit literals, and handle non-traces
   ;; when we come across them.  Better is to convert them
   ;; immediately.  If we encounter a value that isn't a trace, it is
   ;; an error.

   ;; break out to DrRacket (maybe - with no hiding produces a lot of stuff)!

   ;; macro step a simple example (+ 1 2)
   (code
    (+ 1 2)
    => (#%app + 1 2)
    => (#%app + (#%datum . 1) (#%datum . 2)))
   }

  {slide
   #:title "Interposition points"
   (code #%app)
   (code #%datum)
   (code #%module-begin)
   (code #%top)
   (code #%top-interaction)
   }

  {slide
   (para
    (code
     (#%datum . 1)
     => (make-trace (make-assignment #:val 1)))
    (tt "=> %1 | (constant 1) | 1"))
   }

  {slide
   (t "try it!")
   }

  {slide
   #:title "Recap: Forward-mode AD"
   (hc-append
    (scale-to-fit (bitmap "images/orig.png")
                  (* 0.45 client-w) (* 0.5 client-h))
    (blank (* 0.05 client-w))
    (arrow 30 0)
    (blank (* 0.05 client-w))
    (cc-superimpose fwd-mode-graph-2 (ghost fwd-mode-graph)))
   }

  ;; ----------------------------------------
  ;; code for forward derivs


  (define D/f-x           (code [x         (top-id (list-ref xs i))]))
  (define D/f-indep-ids   (code [indep-ids (map top-id xs)]))
  (define D/f-result      (code [result    (apply f xs)]))
  (define D/f-fold-init   (code ([tr result]
                                 [deriv-dict (hash)])))
  (define D/f-trace-items (code [z (reverse (trace-items result))]))
  (define D/f-fold-values (code {values
                                 (trace-append dz tr)
                                 (hash-set deriv-dict
                                           (id z) (top-id dz))}))
  (define D/f-for/fold    (code for/fold))

  (define D/f-prim-op-call (code (D/f-prim-op z x indep-ids
                                              tr deriv-dict)))
  (define D/f-let-dz      (code let ([dz #,D/f-prim-op-call])))
  (define D/f-fold        (code (#,D/f-for/fold #,D/f-fold-init
                                          (#,D/f-trace-items)
                                 (#,D/f-let-dz
                                    #,D/f-fold-values))))
  (define D/f-prune-result (code (trace-prune Dresult)))

  (define D/f-full
   (parameterize ((current-font-size (round (* (current-font-size) 9/10))))
     (code
      (define ((D/f i f) . xs)
        (let (#,D/f-x
              #,D/f-indep-ids
              #,D/f-result)

          (define-values (Dresult _)
            #,D/f-fold)

          #,D/f-prune-result)))))

  {slide
   #:title "Forward-mode AD"
   D/f-full}

  {slide
   #:title "Forward-mode AD"
   (replace-within D/f-full 0.15
                   D/f-fold (replace-within D/f-fold 0.5 D/f-for/fold))}

  {slide
   #:title "Forward-mode AD"
   (code
    (for/fold ([sum 0]
               [prod 1])
              ([x (range 1 6)])
      (values (+ x sum)
              (* x prod)))
    =>
    15
    120)}

  (for ([highlight (list D/f-x
                         D/f-indep-ids
                         D/f-result
                         D/f-fold-init
                         D/f-trace-items
                         D/f-let-dz
                         D/f-fold-values
                         D/f-prune-result
                         D/f-prim-op-call)])
      {slide
       #:title "Forward-mode AD"
       (replace-within D/f-full 0.2
                       highlight)})


  ;; z x indep-ids tr deriv-dict

  ;; (define D/f-prim-op-cond-body
  ;;   (code
  ;;    [(eq? (id z) x-symb) (datum . 1.0)]
  ;;    [(memq (id z) indep-ids) (datum . 0.0)]
  ;;    [else
  ;;     (match (expr z)
  ;;       [(list 'constant '())  (datum . ())]
  ;;       [(list 'constant c)    (datum . 0.0)]
  ;;       [(list 'app 'cons x y) (cons& (d x) (d y))]
  ;;       [(list 'app 'car ls)   (car& (d ls))]
  ;;       [(list 'app 'cdr ls)   (cdr& (d ls))]
  ;;       [(list 'app op xs ...)
  ;;        (let ([xs& (map I xs)])
  ;;          (for/fold ([acc (datum . 0.0)])
  ;;                    ([x xs]
  ;;                     [i (in-naturals)])
  ;;            (define #,(tt "D_i_op") (apply partial i op xs&))
  ;;            (+& (*& #,(tt "D_i_op") (d x)) acc)))])]))

  {slide
   (code
    (code:comment "D/f-prim-op: assignment? symbol? (Listof symbol?)")
    (code:comment "  trace? (HashTable symbol? symbol?) -> trace?")
    (define (D/f-prim-op z x-symb indep-ids
                         tr deriv-dict)
      #,(para)
      (code:comment "I : symbol? -> trace?")
      (define (I s) (trace-get s tr))
      #,(blank 0 (* 0.2 (current-line-sep)))
      (code:comment "d : symbol? -> trace?")
      (define (d s) (I (hash-ref deriv-dict s)))
      #,(para)
      (cond
        (code:comment "...")
        ; #,D/f-prim-op-cond-body
        )))
   }

  {slide
   (code
    (code:comment "...")
    (cond
      [(eq? (id z) x-symb) (datum . 1.0)]
      [(memq (id z) indep-ids) (datum . 0.0)]
      [else
       (match (expr z)
         (code:comment "...")
         )]))
   }

  {slide
   (code
    (code:comment "...")
    (match (expr z)
      [(list 'constant '())  (datum . null)]
      [(list 'constant c)    (datum . 0.0)]
      (code:comment "...")
      ))}

  {slide
   (code
    (code:comment "...")
    (match (expr z)
      (code:comment "...")
      [(list 'app op xs ...)
       (let ([xs& (map I xs)])
         (for/fold ([acc (datum . 0.0)])
                   ([x xs]
                    [i (in-naturals)])
           (define #,(tt "D_i_op") (apply partial i op xs&))
           (+& (*& #,(tt "D_i_op") (d x)) acc)))]
      ))}

  {slide
   (code
    (code:comment "...")
    (match (expr z)
      (code:comment "...")
      [(list 'app 'cons x y) (cons& (d x) (d y))]
      [(list 'app 'car ls)   (car&  (d ls))]
      [(list 'app 'cdr ls)   (cdr&  (d ls))]
      (code:comment "...")))}

  {slide
   (scale/improve-new-text
    (para
     (code (cons 'a 'b) => (a . b))
     (code (cons 'a null) => (a))
     (code (cons 'a (cons 'b null)) => (a b))
     (code (list 'a 'b) => (a b)))
    1.2)
   }

  {slide
   (scale/improve-new-text
    (para
     (code (cons 'a 'b) => (a . b))
     (code (car (cons 'a 'b)) => 'a)
     (code (cdr (cons 'a 'b)) => 'b))
    1.3)
   }

  {slide
   (scale/improve-new-text
    (code   ((D cons) (f x) (g y))
          = (cons ((D f) x) ((D g) y)))
    1.3)
   }

  {slide
   (scale/improve-new-text
    (code   ((D car) (cons (f x) (g y)))
          = ((D f) x))
    1.3)
   }

  {slide
   (scale/improve-new-text
    (code   ((D cdr) (cons (f x) (g y)))
          = ((D g) y))
    1.3)
    }

  {slide
   (t "try it!")}



  ;; ----------------------------------------
  ;; Reverse-mode transformation

  {slide
   #:title "Recap: Reverse-mode AD"
   (hc-append
    (scale-to-fit (bitmap "images/orig.png")
                  (* 0.45 client-w) (* 0.5 client-h))
    (blank (* 0.05 client-w))
    (arrow 30 0)
    (blank (* 0.05 client-w))
    (cc-superimpose rev-mode-graph-2 (ghost rev-mode-graph)))
   }

  (define A/r-Aw-terms
    (code
     (define Aw-terms
       (for/list ([k (hash-ref adjoint-terms (id w))])
         (trace-get k tr)))))

  (define A/r-Aw
    (code
     (define Aw
       (trace-append
        (foldl cons-add (car Aw-terms) (cdr Aw-terms))
        tr))))

  (define A/r-A/r-prim-op
    (code (define-values (tr* adjoint-terms*)
            (A/r-prim-op w Aw adjoint-terms))))

  (define A/r-values
    (code
     {values tr*
             adjoint-terms*
             (hash-set adjoints (id w) (top-id Aw))}))

  (define A/r-loop-body
    (code
     #,A/r-Aw-terms

     #,(blank 0 (* 0.5 (current-line-sep)))

     #,A/r-Aw

     #,(blank 0 (* 0.5 (current-line-sep)))

     #,A/r-A/r-prim-op

     #,(blank 0 (* 0.5 (current-line-sep)))

     #,A/r-values
     ))


  (define A/r-last-step
    (code
     (let* ([tr* (trace-add
                  tr
                  (make-assignment #:val 0.0))]
            [zero-id (top-id tr*)])
       (trace-prune
        (apply
         list&
         (for/list ([x indep-ids])
           (trace-get
            (hash-ref adjoints x zero-id)
            tr*)))))))

  (define A/r-for/fold-iter
    (code
     [w (trace-items result-tr)]))

  (define A/r-for/fold-accs
    (code
     [tr seed-tr]
     [adjoint-terms
      (hash seed-id
            (list (top-id seed-tr)))]
     [adjoints (hash)]))

  (define A/r-outline
    (code
     (define (A/r result-tr indep-ids s)
       (define seed-id (top-id result-tr))
       (define seed-tr (trace-append s result-tr))
       #,(blank 0 (* 0.5 (current-line-sep)))
       (define-values (tr _ adjoints)
         (for/fold (#,A/r-for/fold-accs)
                   #,(blank 0 (* 0.5 (current-line-sep)))
                   (#,A/r-for/fold-iter)
           #,(blank 0 (* 0.5 (current-line-sep)))
           (code:comment "...")
           ))
       (code:comment "...")
       )))

  {slide
   A/r-outline}

  {slide
   (code
    (for/fold ([sum 0]
               [prod 1])
              ([x (range 1 6)])
      (values (+ x sum)
              (* x prod)))
    =>
    15
    120)
   }

  {slide
   (replace-within A/r-outline 0.2
                   A/r-for/fold-iter)
   }

  {slide
   (replace-within A/r-outline 0.2
                   A/r-for/fold-accs)
   }

  (define A/r-loop
    (code
     (for/fold (...)
               ([w (trace-items result-tr)])
       #,A/r-loop-body
       )))

  {slide
   A/r-loop
   }

  (for/list ([code-part (list A/r-Aw-terms
                              A/r-Aw
                              A/r-A/r-prim-op
                              A/r-values)])
    {slide
     (replace-within A/r-loop 0.2
                     code-part)
     })

  {slide
   (code
    (code:comment "...")
    #,A/r-last-step)
   }

  {slide
   (code
    w ← (cons x y))
   (para (tt "=>"))
   (code
    Ax ← (car Aw)
    Ay ← (cdr Aw))
   }

  {slide
   (code
    w ← (car xs))
   (para (tt "=>"))
   (code
    (car Axs) ← Aw)}


  {slide
   (code
    w ← (cdr xs))
   (para (tt "=>"))
   (code
    (cdr Axs) ← Aw)}

  {slide
   (code
    w ← (car xs))
   (para (tt "=>"))
   (code
    Axs ← (cons Aw (cons-zero (cdr xs))))}

  {slide
   (code
    w ← (cdr xs))
   (para (tt "=>"))
   (code
    Axs ← (cons (cons-zero (car xs)) Aw))
   }

  ;; A/r-prim-op
  ;; {slide
  ;;  (code
  ;;   (define (A/r-prim-op w Aw adjoint-terms)
  ;;     #,(para)
  ;;     (match (expr w)
  ;;       (code:comment "...")
  ;;       [(list 'app 'cons x y)
  ;;        (let ([Ax (car& Aw)]
  ;;              [Ay (cdr& Aw)])
  ;;          {values (trace-append Ay Ax Aw)
  ;;                  (upd-adj adjoint-terms
  ;;                           x Ax
  ;;                           y Ay)})]
  ;;       (code:comment "...")
  ;;       )))
  ;;  }

  ;; {slide
  ;;  (code
  ;;   (define (A/r-prim-op w Aw adjoint-terms)
  ;;     #,(para)
  ;;     (match (expr w)
  ;;       (code:comment "...")
  ;;       [(list 'app 'cons x y)
  ;;        (let ([Ax (car& Aw)]
  ;;              [Ay (cdr& Aw)])
  ;;          {values (trace-append Ay Ax Aw)
  ;;                  (upd-adj adjoint-terms
  ;;                           x Ax
  ;;                           y Ay)})]
  ;;       (code:comment "...")
  ;;       )))
  ;;  }

  {slide
   (t "try it!")
   }

  ;; ----------------------------------------
  ;; program transformation

  {slide
   #:title "Program transformation"
   (para "Can apply the previous work to straight-line code, at compile time")
   (para (code define) "instead of" (code assignment))
   }

  {slide
   #:title "Program transformation"
   (ht-append
    (vl-append
     (tt "#lang rackpropagator/⬋ ")
     (tt "  straightline")
     (hb-append
      (code
       (define (f x y)
         (define a (+ x y))
         (define b (+ a a))
         (define c (* a y))
         (define d 1.0)
         (+ c d)))
      (arrow 30 0)))
    (code
     (define (Df x y)
       (define a (+ x y))
       (define %2 1.0)
       (define %3 1.0)
       (define %4 (* %2 %3))
       (define %7 (* %4 y))
       (define %8 (* %4 a))
       (define %9 1.0)
       (define %10 (* %7 %9))
       (define %11 1.0)
       (define %12 (* %7 %11))
       (define %17 (+ %8 %12))
       (define %19 '())
       (define %20 (cons %17 %19))
       (cons %10 %20))))
   }

  {slide
   #:title "Program transformation"
   (code
    (define-syntax (define/d stx)
      (syntax-case stx ()
        [(_ (f args ...) body ...)
         (with-syntax
           ([(body* ...)
             (handle-assignments #'(args ...)
                                 #'(body ...))])
           #'(define (f args ...)
               body* ...))])))
   'next
   (code (provide (rename-out [define/d define])))
   }

  ;; ----------------------------------------

  ;; {slide
  ;;  ;; language model
  ;;  (code
  ;;   (define #,(it "x") #,(it "E"))
  ;;   ...
  ;;   #,(blank 0 20)
  ;;     #,(t "where")
  ;;   #,(it "E") = (#,(it "op") #,(it "x") ...)
  ;;   #,(ghost (it "E")) $ #,(it "c")
  ;;   #,(it "x : symbol")
  ;;   #,(it "c : numeric constant")
  ;;   #,(it "op : primitive operation"))
  ;;  }

  ;; {slide
  ;;  (code
  ;;   #,(it "M") = (define #,(it "x") #,(it "c"))
  ;;   #,(ghost (it "M")) $ (define #,(it "x") #,(it "O"))
  ;;   #,(ghost (it "M")) $ (define #,(it "x") #,(it "E"))
  ;;   #,(ghost (it "M")) $ (define #,(hc-append (it "x") (subscript (it "0"))) (if #,(hc-append (it "x") (subscript (it "1"))) #,(hc-append (it "E") (subscript (it "0"))) #,(hc-append (it "E") (subscript (it "1")))))
  ;;   #,(ghost (it "M")) $ (define (#,(it "x") ...) #,(it "M") ...)

  ;;   #,(blank 0 20)
  ;;     #,(t "where")
  ;;   #,(it "O") = (#,(it "op") #,(it "x") ...)
  ;;   #,(it "E") = (#,(hc-append (it "x") (subscript (it "0"))) #,(hc-append (it "x") (subscript (it "1"))) ...)
  ;;   #,(it "x : symbol")
  ;;   #,(it "c : numeric constant")
  ;;   #,(it "op : primitive operation"))
  ;;  }



  ;; ----------------------------------------

  ;; functions-as-values too (need to extend trace)?


  {slide
   #:title "Dual numbers"
   'next
   (para "sum-of-squares:")
   'alts
   (list
    (list
     (para "Given" (code a) "and" (code b) #:align 'center)

     (code c ← (* a a)
           d ← (* b b)
           e ← (+ c d))

     'next

     (t "The \"forward-mode\" transformation:")
     (code
      #,(D c) ← (+ (* a #,(D a)) (* #,(D a) a))
      #,(D d) ← (+ (* b #,(D b)) (* #,(D b) b))
      #,(D e) ← (+ #,(D c) #,(D d))))
    (list
     (para "Can interleve the operations computing" (it "x") "and" (D #,(it "x")))
     (code
      c ← (* a a)
      #,(D c) ← (+ (* a #,(D a)) (* #,(D a) a))
      d ← (* b b)
      #,(D d) ← (+ (* b #,(D b)) (* #,(D b) b))
      e ← (+ c d)
      #,(D e) ← (+ #,(D c) #,(D d)))
     (item (para (code #,(D x)) "depends on" (code #,(D y))
                 "if and only if" (code x) "depends on" (code y)))
     (item (para (code #,(D x)) "depends on" (code y)
                 "only if" (code x) "depends on" (code y)))
     ))
   }

  {slide
   #:title "Dual numbers"
   (para "Idea: treat the pair of" (code x) "and" (code #,(D x))
         "as a single entity.  Define combined operations.") }

  {slide
   #:title "Dual numbers"
   (code
    (struct dual-number (p d) #:transparent))
   'next
   'alts
   (list
    (list
     (code
      (define (primal x)
        (cond
          [(dual-number? x) (dual-number-p x)]
          [(number? x) x]
          [else (raise-argument-error
                 'primal "number? or dual-number?" x)]))))
    (list
     (code
      (define (dual x)
        (cond
          [(dual-number? x) (dual-number-d x)]
          [(number? x) (zero x)]
          [else (raise-argument-error
                 'dual "number? or dual-number?" x)])))))
   }

  (define dual-+-expr
    (code (dual-number (+ (primal x) (primal y))
                       (+ (dual x) (dual y)))))

  (define dual-+-full
    (code
     (define (dual-+ x y)
       (if (or (dual-number? x) (dual-number? y))
           #,dual-+-expr
           (+ x y)))))

  {slide
   #:title "Dual numbers"
   dual-+-full}

  {slide
   #:title "Dual numbers"
   (replace-within dual-+-full 0.2 dual-+-expr)
   }

  (define dual-*-expr
    (code
     (dual-number (* (primal x) (primal y))
                  (+ (* (dual x) (primal y))
                     (* (primal x) (dual y))))))

  (define dual-*-full
    (code
     (define (dual-* x y)
       (if (or (dual-number? x) (dual-number? y))
           #,dual-*-expr
           (* x y)))))

  {slide
   #:title "Dual numbers"
   dual-*-full
   }

  {slide
   #:title "Dual numbers"
   (replace-within dual-*-full 0.2 dual-*-expr)}


  {slide
   #:title "Dual numbers"
   (para
    (code
     (code:comment "...")

     (define (dual-log x)
       (if (dual-number? x)
           (dual-number (log (primal x))
                        (/ (dual x) (primal x)))
           (log x)))

     (code:comment "...")))
   }

  {slide
   #:title "Dual numbers"
   (item (bt "only") "need to define the primitive numerical functions")
   (item "Can be implemented with operator overloading")
   (item "A" (bt "local") "program transformation")
   }

  (define i=n (code (= i n)))
  (define dual-1 (code (dual-number a 1)))
  (define dual-0 (code (dual-number a 0)))
  (define get-dual-part-D (code (get-dual-part (apply f args*))))
  (define dual-number-D-for/list
    (code
     (for/list [(i (in-naturals))
                (a args)]
       (if (= i n)
           #,dual-1
           #,dual-0))))

  (define dual-number-D
    (code
     (define ((D n f) . args)
       (let ([args* #,dual-number-D-for/list])
         #,get-dual-part-D))))


  {slide
   #:title "Dual numbers: Differentiation"
   'alts
   (list
    (list dual-number-D)
    (list
     ;(replace-within
     (replace-within dual-number-D 0.2
                     dual-number-D-for/list))
    (list
     (replace-within dual-number-D 0.2
                     dual-1))
    (list
     (replace-within dual-number-D 0.2
                     dual-0))
    (list
     (replace-within dual-number-D 0.2
                     get-dual-part-D)))

   'next
   (para
    "Helper function:"
    (code
     (get-dual-part
      (list (dual-number 0.0 1.0)
            2.0
            (cons (dual-number 3.0 0.0)
                  (dual-number 4.0 5.0)))))
    "=>" (code (1.0 0.0 (0.0 . 5.0))))
   }

  {slide
   (t "try it!")
   }

  {slide
   (big (t "http://github.com/ots22/rackpropagator"))
   }

  (define (cite type [year #f] #:url url #:title title #:authors authors)
    (para
     (small (caps (t type))) (italic (para title))
     (if (pict? url) (para url) (para (tt url)))
     (para authors (if year (string-append "(" year ")") ""))))

  {slide
   #:title "References"
   (cite "talk"
         #:url     "https://youtu.be/NkJNcEed2NU"
         #:title   "From automatic differentiation to message passing"
         #:authors "Tom Minka")

   (cite "paper"   "2018"
         #:url     "https://arxiv.org/abs/1804.00746"
         #:title   "The simple essence of automatic differentiation"
         #:authors "Conal Elliot")

   (cite "talk"
         #:url     "https://youtu.be/Shl3MtWGu18"
         #:title   "The simple essence of automatic differentiation"
         #:authors "Conal Elliot")
   }
  {slide
   #:title "References"
   (cite "paper" "2008"
         #:url (para (tt "https://www.bcl.hamilton.ie⬋")
                     (tt "    /~barak/papers/toplas-reverse.pdf")
                     (tt "doi:10.1145/1330017.1330018"))

         #:title   "Reverse-Mode AD in a Functional Framework: Lambda the Ultimate Backpropagator"
         #:authors "Pearlmutter & Siskind")

   (cite "paper" "2018"
         #:url     "https://arxiv.org/abs/1803.10228"
         #:title   "Demystifying Differentiable Programming: Shift/Reset the Penultimate Backpropagator"
         #:authors (list "Fei Wang" (it "et al.")))
   }

  {slide
   #:title "References"
   (cite "book" "2015"
         #:url
         (para (tt "https://mitpress.mit.edu/sites/default/files⬋")
               (tt "    /titles/content/sicm_edition_2/book.html"))
         #:title   "Structure and Interpretation of Classical Mechanics (2nd ed.)"
         #:authors "Gerald Jay Sussman & Jack Wisdom")

   (scale-to-fit (bitmap "images/sicm-cover.jpg") (* 0.5 client-w) (* 0.5 client-h))
   }

  {slide
   #:title "References"

   (cite "website"
         #:title "autodiff.org: Community Portal for Automatic Differentiation"
         #:url "http://www.autodiff.org/"
         #:authors "")

   (cite "book"
         #:title "Beautiful Racket: an introduction to language-oriented programming using Racket, v1.6"
         #:authors "Matthew Butterick"
         #:url "https://beautifulracket.com/")}

  ;(start-at-recent-slide)
  (set-page-numbers-visible! #t)


  );; module slideshow



  ;; {slide
  ;;  (plot (list
  ;;         (function (λ (x) (sqrt x)) 0 10
  ;;                   #:label "sqrt(x)")
  ;;         (function (λ (x) (+ (* 0.25 x) 1)) 0 10
  ;;                   #:label "D sqrt(x)")))}



;; (module+ slideshow
;;   (slide
;;    #:title "racket in one slide"
;;    (code
;;     (code:comment "function application")
;;     (print x)
;;     (+ 1 2 3) (code:comment " => 6")
;;     (= (+ 9 16) 25)   (code:comment " => #t")

;;     (code:comment "quotation")
;;     (quote a)
;;     'a
;;     '(+ 1 2 3)

;;     (code:comment "conses and lists")
;;     (cons 1 2) (code:comment " => '(1 . 2)")
;;     (cons 1 (cons 2 3))    (code:comment " => '(1 . (2 . 3))")
;;     (code:comment "      = '(1 2 . 3)")
;;     (cons 1 (cons 2 '()))  (code:comment " => '(1 . (2 . ()))")
;;     (code:comment "      = '(1 2)")
;;     (list 1 2)             (code:comment " same ")

;;     (code:comment "anonymous functions")
;;     (lambda (x) (/ 1 x))

;;     ; higher order functions
;;     (map cos (list 0 (/ pi 4) (/ pi 2)))
;;     ; true/false
;;     ))


;;   (slide
;;    #:title "racket in one slide"
;;    (let ()
;;      (define-exec-code (p r s)
;;        (+ 1 1)
;;        )
;;      p
;;      )
;;    )

;;   (slide
;;    #:title "interactive"
;;    (repl-area #:width client-w #:height (* 0.7 client-h))
;;    )

;;   (slide
;;    #:title "...well two slides"
;;    (code
;;     (code:comment "syntax")
;;     #'(f x)))




;;   ; define a slide that, given a function, returns a slide with the plot, and it's derivative, like the above
;;   ;(define (slide f)
;;   ;  )

;; ) ; module slideshow

