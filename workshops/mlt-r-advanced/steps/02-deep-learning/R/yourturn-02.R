# Your turn (Parsons) — reorder these lines into a correct fused forward().
# Goal: run the three branches, concatenate along dim = 2, then the head.
# Which widths must match? What is the output dim? (hint: head expects 16 + sig_ch + hidden)
#
#   self$head(torch_cat(list(t, c, r), dim = 2))
#   r <- self$rnn(x_seq)
#   t <- self$tab(x_tab)
#   c <- self$cnn(x_sig)
#
# Correct order: build t, c, r (any order), THEN concat, THEN head.
