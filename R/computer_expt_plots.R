#------------------------------------------------
# Computer Experiment Plotting Tools
#------------------------------------------------
# Libraries
library(ggplot2)
library(tidyr)
library(dplyr)
library(grid)
library(gridExtra)
library(reshape2)
library(DescTools)
library(viridis)


#------------------------------------------------
# Colors and line types
def_colors = c('red',"blue","green3","orange","purple","gold",'cyan',"grey30","pink")
def_lines = rep("solid",length(def_colors))

#------------------------------------------------
# 1D plots
#------------------------------------------------
# Plot 1D mena with uncertainty bounds
plot_mean1d = function(x, pmean, plb = NULL, pub = NULL, y_lim = NULL,
                       amean = NULL,apts_x = NULL, apts_y = NULL, apts_sz = 1.2, apts_col = "black", 
                       apts_pch = 16, apts_alpha = 1,
                       title = 'Mean Function', y_lab = "f(x)", x_lab = "x", in_labs = NULL,
                       colors = def_colors, line_type_list = def_lines){
  
  # Make sure lb, ub and mean are same column sizes 
  if(is.null(pub)){pub = pmean}
  if(is.null(plb)){plb = pmean}

  if(!is.null(amean)){
    pmean = cbind(amean,pmean)
    plb = cbind(amean,plb)
    pub = cbind(amean,pub)
  }
  
  df = data.frame(x = x, f = pmean, flb = plb, fub = pub)
  rownames(df) = NULL
  if(is.matrix(pmean)){K = ncol(pmean)}else{K=1}
  colnames(df) = c("x",paste0("f",1:K),paste0("flb",1:K),paste0("fub",1:K))
  
  df_mean = df %>% select(c(x,paste0("f",1:K)))
  df_lb = df %>% select(c(x,paste0("flb",1:K)))
  df_ub = df %>% select(c(x,paste0("fub",1:K)))
  
  df_mean = df_mean %>% pivot_longer(!x,names_to = "f", values_to = "mean")
  df_lb = df_lb %>% pivot_longer(!x,names_to = "f", values_to = "lb")
  df_ub = df_ub %>% pivot_longer(!x,names_to = "f", values_to = "ub")
  
  df_bounds = cbind(df_lb,df_ub[,"ub"]) 
  df_bounds[,'f'] = gsub("flb","f",df_bounds[,'f'])
  
  if(is.null(in_labs)){in_labs = paste0("f",1:K)}
  p = df_mean %>% ggplot() +
    geom_line(aes(x, mean, color = f, linetype = f), size = 1.1) + 
    geom_ribbon(data = df_bounds, aes(x = x, ymin=lb, ymax=ub, fill = f), alpha=0.2) +
    scale_linetype_manual(values = line_type_list, name = "", labels = in_labs) +
    scale_color_manual(values = colors, name = "", labels = in_labs) +
    scale_fill_manual(values = colors, name = "", labels = in_labs) +
    theme_bw() +
    theme(axis.line = element_line(color = "grey70"),
          panel.border = element_blank(),plot.title = element_text(hjust = 0.5),
          legend.position = "bottom", legend.text = element_text(size = 10)) +
    labs(x = x_lab, y = y_lab, title = title) +
    coord_cartesian(ylim = y_lim) +
    guides(size = 'none')
  
  
  if(!is.null(apts_x) & !is.null(apts_y)){
    p = p + geom_point(data = data.frame(x0=apts_x,y0=apts_y), aes(x0,y0), size= apts_sz, 
                       pch = apts_pch, color = apts_col, alpha = apts_alpha) 
  }
  return(p)
}


#------------------------------------------------
# 2D plots
#------------------------------------------------
# Mean surface for 2d function with color scale provideddf_bounds
plot_mean2d_gradient = function(x_test,pmean,xcols = c(1,2), title=NULL,xlab = "x1",ylab = "x2",
                        flab = "Values",scale_colors = c("navy","white","darkred"),
                        scale_vals = NULL){
  hm_data = data.frame(x_test, Values = pmean)
  x1name = paste0('X',xcols[1])
  x2name = paste0('X',xcols[2])
  colnames(hm_data)[1:2] = c('x1', 'x2')
  
  if(is.null(title)){title = paste("Mean Predictions",x1name,"vs.",x2name)}
  if(is.null(scale_vals)){scale_vals = c(min(pmean),median(pmean),max(pmean))}
  
  p = ggplot(hm_data) + 
    geom_raster(interpolate = TRUE, aes(x1,x2,fill=Values)) +
    labs(x = x1name, y = x2name, title = title) + 
    theme_bw() +
    theme(axis.line = element_line(color = "grey70"),
          panel.border = element_blank(),plot.title = element_text(hjust = 0.5),
          legend.position = "right", legend.text = element_text(size = 10)) +
    labs(x = xlab, y = ylab, fill = flab)
  #if(viridis_scale){
  #  p = p + scale_fill_viridis(option = viridis_opt, limits = scale_vals[c(1,3)])
  #}
  if(length(scale_colors) != 3){
    p = p + scale_fill_gradientn(colors = scale_colors, 
                                 values = scales::rescale(scale_vals),
                                 limits = scale_vals[c(1,length(scale_vals))])
  }else{
    p = p + scale_fill_gradient2(low = scale_colors[1], high = scale_colors[3], 
                                 mid = scale_colors[2], 
                           midpoint = scale_vals[2], limits = scale_vals[c(1,3)])
  }
  return(p)
}



plot_mean2d_viridis = function(x_test,pmean,xcols = c(1,2), title=NULL,xlab = "x1",ylab = "x2",
                               flab = "Values",viridis_opt = "viridis",
                               scale_limits = NULL){
  hm_data = data.frame(x_test, Values = pmean)
  x1name = paste0('X',xcols[1])
  x2name = paste0('X',xcols[2])
  colnames(hm_data)[1:2] = c('x1', 'x2')
  
  if(is.null(title)){title = paste("Mean Predictions",x1name,"vs.",x2name)}
  if(is.null(scale_limits)){scale_vals = c(min(pmean),max(pmean))}

  p = ggplot(hm_data) + 
    geom_raster(interpolate = TRUE, aes(x1,x2,fill=Values)) +
    labs(x = x1name, y = x2name, title = title) + 
    theme_bw() +
    theme(axis.line = element_line(color = "grey70"),
          panel.border = element_blank(),plot.title = element_text(hjust = 0.5),
          legend.position = "right", legend.text = element_text(size = 10)) +
    labs(x = xlab, y = ylab, fill = flab)
  p = p + scale_fill_viridis(option = viridis_opt, limits = scale_limits)
}



# Climate plotting tools
plot_mean2d_map_gradient = function(x_test,pmean,xcols = c(1,2), title=NULL,xlab = "x1",ylab = "x2",
                                    flab = "Values",scale_colors = c("navy","white","darkred"),
                                    scale_vals = NULL, maps_list = NULL, maps_cols = NULL,
                                    lat_bnds = NULL, lon_bnds = NULL){
  p = plot_mean2d_gradient(x_test,pmean,xcols,title,xlab,ylab,flab,scale_colors,scale_vals)
  
  if(!is.null(maps_list)){
    if(length(maps_cols) != length(maps_list)){
      maps_cols = c(maps_cols, rep("black", length(maps_list)-length(maps_cols)))      
    }
    if(is.null(lat_bnds)){lat_bnds = c(min(x_test[,2]), max(x_test[,2]))}
    if(is.null(lon_bnds)){lon_bnds = c(min(x_test[,1]), max(x_test[,1]))}
    
    for(i in 1:length(maps_list)){
      p = p + geom_polygon(data = data.frame(maps_list[[i]]), aes(x = long, y= lat, group = group), 
                           fill = NA, color = maps_cols[i])
    }
    p = p + scale_x_continuous(expand = c(0,0)) +
      scale_y_continuous(expand = c(0,0)) +
      coord_cartesian(xlim = lon_bnds, ylim = lat_bnds)
  }
  return(p)
}


plot_mean2d_map_viridis = function(x_test,pmean,xcols = c(1,2), title=NULL,xlab = "x1",ylab = "x2",
                               flab = "Values",viridis_opt = "viridis",
                               scale_limits = NULL, maps_list = NULL, maps_cols = NULL,
                               lat_bnds = NULL, lon_bnds = NULL){
  p = plot_mean2d_viridis(x_test,pmean,xcols,title,xlab,ylab,flab,viridis_opt,scale_limits)
  
  if(!is.null(maps_list)){
    if(length(maps_cols) != length(maps_list)){
      maps_cols = c(maps_cols, rep("black", length(maps_list)-length(maps_cols)))      
    }
    if(is.null(lat_bnds)){lat_bnds = c(min(x_test[,2]), max(x_test[,2]))}
    if(is.null(lon_bnds)){lon_bnds = c(min(x_test[,1]), max(x_test[,1]))}
    
    for(i in 1:length(maps_list)){
      p = p + geom_polygon(data = data.frame(maps_list[[i]]), aes(x = long, y= lat, group = group), 
                           fill = NA, color = maps_cols[i])
    }
    p = p + scale_x_continuous(expand = c(0,0)) +
      scale_y_continuous(expand = c(0,0)) +
      coord_cartesian(xlim = lon_bnds, ylim = lat_bnds)
  }
  return(p)
}



# Covaraince Kernel 
plot_kernel_viridis=function(k_matrix, vopt = 'viridis',
                             title = "Kernel", k_lim = c(0,0.5,1)){
  # Format data
  n = nrow(k_matrix)
  k_data = expand.grid(x1=1:n, x2=1:n)
  k_data$z = matrix(k_matrix,ncol=1)
  
  # Make plot
  p = k_data %>% ggplot(aes(x1, x2, fill = z)) +
    geom_tile() +
    theme_bw() +
    theme(panel.border = element_blank(), panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(colour = "grey70"),legend.text = element_text(size = 10),
          plot.title = element_text(hjust = 0.5, size = 16),
          legend.key.size = unit(0.8, 'cm')) +
    labs(x = 'Index',y = 'Index',fill = "Kernel", title = title) +
    scale_y_reverse()
  p = p + scale_fill_viridis(option = vopt,limits = c(k_lim[1],k_lim[3]))
  return(p)
}

# The ultimate legend pull
g_legend = function(gplt){
  temp = ggplot_gtable(ggplot_build(gplt))
  leg = which(sapply(temp$grobs, function(x) x$name == "guide-box"))
  legend = temp$grobs[[leg]]
  return(legend)
}

