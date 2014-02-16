
check_stack <- function(s){
  inherits(s, "stack") && length(s[["thickness"]] == length(s[["epsilon"]]))
}

##' invert the description of a multilayer to simulate the opposite direction of incidence
##'
##' inverts list of epsilon and thickness of layers
##' @title rev.stack
##' @param x stack
##' @return stack
##' @family helping_functions user_level stack
##' @S3method rev stack
##' @author Baptiste Auguie
rev.stack <- function(x) {
  x[["epsilon"]] <- rev(x[["epsilon"]])
  x[["thickness"]] <- rev(x[["thickness"]])
  x
}


##' @S3method c stack
c.stack <- function(..., recursive = FALSE){
  sl <- list(...)
  
  tl <- lapply(sl, "[[", "thickness")
  el <- lapply(sl, "[[", "epsilon")
  
  ll <- list(epsilon=do.call(c, el), 
             thickness=do.call(c, tl))
  structure(ll, class="stack")
}

##' @S3method print stack
print.stack <- function(x, ...){
  str(x)
}

##' @S3method plot stack
plot.stack <- function(x, ...){
  xx <- c(0, cumsum(x[['thickness']]))
  material <- epsilon_label(x[['epsilon']])
  plot(xx, 0*xx, t="n", ylim=c(0,1), yaxt="n", ylab="", bty="n",
       xlab=expression(x/nm), ...)
  rect(xx[-length(xx)], 0, xx[-1], 1, col=material)
}

##' @importFrom ggplot2 fortify
##' @S3method fortify stack
fortify.stack <- function(model, data, ...){
  
  xx <- c(0, cumsum(model[['thickness']]))
  material <- epsilon_label(model[['epsilon']])
  N <- length(xx)
  data.frame(xmin=xx[-N],
             xmax=xx[-1],
             material = material)
  
}

##' @importFrom ggplot2 autoplot
##' @S3method autoplot stack
autoplot.stack <- function(object, ...){
  ggplot(object) + 
    expand_limits(y=c(0,1))+
    geom_rect(aes(xmin=xmin, xmax=xmax, 
                  ymin=-Inf, ymax=Inf, fill=material))+
    scale_x_continuous(expression(x/nm),expand=c(0,0))+
    scale_y_continuous("", expand=c(0,0), breaks=NULL)+
    theme_minimal() +
    scale_fill_brewer(palette="Paired")+
    #     theme(legend.position="top")+
    #     guides(fill = guide_legend(direction="horizontal")) +
    theme()
  
}

##' Single-layer stack structure
##'
##' returns a stack describing a single layer
##' @title layer_stack
##' @export
##' @param epsilondielectric function (numeric, character, or complex)
##' @param thickness layer thickness in nm
##' @param ... ignored
##' @return list of class 'stack'
##' @author baptiste Auguie
##' @family stack user_level
layer_stack <- function(epsilon="epsAu", thickness=50, ...){
  ll <- list(epsilon=list(epsilon), thickness=thickness)
  structure(ll, class="stack")
}

##' Embed stack structure
##'
##' embeds a stack in semi-infinite media
##' @title embed_stack
##' @export
##' @param s stack (finite structure)
##' @param nleft real refractive index on the left side
##' @param nright real refractive index on the right side
##' @param dleft dummy layer thickness in nm
##' @param dright dummy layer thickness in nm
##' @param ... ignored
##' @return list of class 'stack'
##' @author baptiste Auguie
##' @family stack user_level
embed_stack <- function(s, nleft=1.0, nright=1.0,
                        dleft= 200, dright=200, ...){
  
  Nlay <- length(s[["thickness"]])
  if(s[["thickness"]][1] == 0L && s[["thickness"]][Nlay] == 0L)
    warning("already embedded?")
  
  s[["thickness"]] <- c(0, dleft, s[["thickness"]], dright, 0)
  s[["epsilon"]] <- c(nleft^2, nleft^2, s[["epsilon"]], 
                      nright^2, nright^2)
  
  s
}
##' DBR stack structure
##'
##' periodic structure of dielectric layers
##' @title dbr_stack
##' @export
##' @param lambda0 central wavelength of the stopband
##' @param n1 real refractive index for odd layers
##' @param n2 real refractive index for even layers
##' @param d1 odd layer thickness in nm
##' @param d2 even layer thickness in nm
##' @param N number of layers, overwrites pairs
##' @param pairs number of pairs
##' @param ... ignored
##' @return list of class 'stack'
##' @author baptiste Auguie
##' @family stack user_level
dbr_stack <- function(lambda0=630, 
                      n1=1.28, n2=1.72, 
                      d1=lambda0/4/n1, d2=lambda0/4/n2,
                      N=2*pairs, pairs=4, ...){
  epsilon <- rep(c(n1^2, n2^2), length.out=N)
  thickness <- rep(c(d1,d2), length.out=N)
  
  ll <- list(epsilon=epsilon, thickness=thickness)
  structure(ll, class="stack")
}

##' DBR-metal stack structure
##'
##' periodic structure of dielectric layers against metal film
##' @title tamm_stack
##' @export
##' @param lambda0 central wavelength of the stopband
##' @param n1 real refractive index for odd layers
##' @param n2 real refractive index for even layers
##' @param d1 odd layer thickness in nm
##' @param d2 even layer thickness in nm
##' @param N number of layers, overwrites pairs
##' @param pairs number of pairs
##' @param nx1 real refractive index for last odd layer
##' @param nx2 real refractive index for last even layer
##' @param dx1 variation of last odd layer thickness in nm
##' @param dx2 variation of last even layer thickness in nm
##' @param dm thickness of metal layer
##' @param metal character name of dielectric function
##' @param nleft refractive index of entering medium
##' @param nright refractive index of outer medium
##' @param position metal position relative to DBR
##' @param ... ignored
##' @return list of class 'stack'
##' @author baptiste Auguie
##' @family stack user_level
tamm_stack <- function(lambda0=630, 
                       n1=1.28, n2=1.72, 
                       d1=lambda0/4/n1, d2=lambda0/4/n2,
                       N=2*pairs, pairs=4, 
                       dx1 = 0, dx2 = 0,
                       dm=50, metal="epsAu",
                       position=c("after", "before"),
                       incidence = c("left", "right"),
                       nleft = 1.5, nright=1.0,
                       ...){
  position <- match.arg(position)
  incidence <- match.arg(incidence)
  
  dbr <- dbr_stack(lambda0=lambda0, 
                   n1=n1, n2=n2, 
                   d1=d1, d2=d2,
                   N=N-2, pairs=pairs-1)
  
  variable <- dbr_stack(lambda0=lambda0, 
                    n1=n1, n2=n2, 
                    d1=d1 + dx1, d2=d2 + dx2,
                    N=2)
  
  met <- layer_stack(epsilon=metal, thickness=dm)
  
  struct <- switch(position,
                   before = c(met, variable, dbr),
                   after = c(dbr, variable, met))
  
  s <- embed_stack(struct, nleft=nleft, nright=nright, ...) 
  
  switch(incidence,
         left = s,
         right = rev(s))
  
}

##' DBR-metal stack structure
##'
##' periodic structure of dielectric layers against metal film
##' @title tamm_stack_ir
##' @export
##' @param lambda0 central wavelength of the stopband
##' @param n1 real refractive index for odd layers
##' @param n2 real refractive index for even layers
##' @param d1 odd layer thickness in nm
##' @param d2 even layer thickness in nm
##' @param N number of layers, overwrites pairs
##' @param pairs number of pairs
##' @param nx1 real refractive index for last odd layer
##' @param nx2 real refractive index for last even layer
##' @param dx1 variation of last odd layer thickness in nm
##' @param dx2 variation of last even layer thickness in nm
##' @param dm thickness of metal layer
##' @param metal character name of dielectric function
##' @param nleft refractive index of entering medium
##' @param nright refractive index of outer medium
##' @param position metal position relative to DBR
##' @param ... ignored
##' @return list of class 'stack'
##' @author baptiste Auguie
##' @family stack user_level
tamm_stack_ir <- function(lambda0=950, 
                          n1=3, n2=3.7, 
                          d1=lambda0/4/n1, d2=lambda0/4/n2,
                          N=2*pairs, pairs=4, 
                          dx1 = 0, dx2 = 0,
                          dm=50, metal="epsAu",
                          position="after",
                          incidence = "left",
                          nleft = n2, nright=1.0,
                          ...){
  tamm_stack(lambda0=lambda0, 
             n1=n1, n2=n2,
             d1=d1, d2=d2, 
             N=N, pairs=pairs, 
             dx1=dx1, dx2=dx2, 
             dm=dm, metal=metal,
             position=position,
             incidence=incidence,
             nleft=nleft, nright=nright,
             ...)
}


##' simultate the internal field of a multilayer stack
##'
##' wrapper around multilayer_field for a stack structure
##' @title simulate_nf
##' @param fun function returning a stack
##' @param wavelength numeric vector
##' @param angle incident angle in radians
##' @param polarisation p or s
##' @param res number of points
##' @param field logical, return the complex electric field vector
##' @return data.frame
##' @export
##' @family helping_functions user_level stack
##' @author Baptiste Auguie
simulate_nf <- function(..., s=NULL, fun = tamm_stack, 
                        wavelength = 630, 
                        angle=0, polarisation=c("p","s"),
                        res=1e4, 
                        field = FALSE){
  
  polarisation <- match.arg(polarisation)
  psi <- if(polarisation == "p") 0 else pi/2
  
  if(is.null(s)) s <- fun(...)
  stopifnot(check_stack(s))
  
  thickness <- s[["thickness"]]
  Nlay <- length(thickness)
  
  ## check that the stack is embedded with specific substrate and superstrate
  if(!(thickness[1] == 0L && thickness[Nlay] == 0L))
    s <- embed_stack(s)
  
  k0 <- 2*pi/wavelength
  positions <- c(0, cumsum(s[["thickness"]]))
  epsilon <- epsilon_dispersion(s[["epsilon"]], wavelength)
  
  n1 <- Re(sqrt(epsilon[[1]]))
  ## at least 10 points 
  ## stepsize <- min(c(diff(range(positions)) / res, 0.1*diff(positions)))
  stepsize <- diff(range(positions)) / res
  probes <- mapply(seq, positions[-length(positions)], positions[-1], 
                   MoreArgs=list(by=stepsize))
  id <- rep(seq_along(probes), sapply(probes, length))
  d <- unlist(probes)
  
  result <- planar$multilayer_field(k0, k0*sin(angle)*n1, 
                                    unlist(epsilon),  
                                    s[["thickness"]], d, psi)
  if(field)
    return(result[['E']])
  
  ll = as.list(unique(id))
  names(ll) = epsilon_label(s[["epsilon"]])
  material <- factor(id)
  levels(material) = ll
  
  d <- data.frame(x = d, I = Re(colSums(result$E*Conj(result$E))), 
                  Rp = Mod(result$rp)^2, Rs = Mod(result$rs)^2,
                  id=id, material=material)
  attr(d, "stack") <- s
  d
}

##' simultate the far-field response of a multilayer stack
##'
##' wrapper around recursive_fresnelcpp for a stack structure
##' @title simulate_ff
##' @param fun function returning a stack
##' @param wavelength numeric vector
##' @param angle incident angle in radians
##' @param polarisation p or s
##' @return data.frame
##' @export
##' @family helping_functions user_level stack
##' @author Baptiste Auguie
simulate_ff <- function(..., s=NULL, fun = tamm_stack, 
                        wavelength = seq(400, 1000), 
                        angle=0, polarisation=c("p","s")){
  
  polarisation <- match.arg(polarisation)
  
  if(is.null(s)) s <- fun(...)
  stopifnot(check_stack(s))
  
  thickness <- s[["thickness"]]
  Nlay <- length(thickness)
  
  ## check that the stack is embedded with specific substrate and superstrate
  if(!(thickness[1] == 0L && thickness[Nlay] == 0L))
    s <- embed_stack(s)
  
  epsilon <- epsilon_dispersion(s[["epsilon"]], wavelength)
  
  results <- recursive_fresnelcpp(wavelength=wavelength,
                                  angle=angle,
                                  epsilon = epsilon, 
                                  thickness = s[["thickness"]], 
                                  polarisation = polarisation)
  
  d <- data.frame(results[c("wavelength", "angle", "R", "T", "A")])
  attr(d, "stack") <- s
  d
}

