plot_rsa({'group'},'all_time-resolved_chan-all_.*')
saveallfigures('png','all_timeres')
close all
plot_rsa({'group'},'all_time-movingWin_chan-all_.*')
saveallfigures('png','all_timemavg')
close all
plot_rsa({'group'},'noise_ws_time-resolved_chan-all_.*')
saveallfigures('png','noise_ws_timeres')
close all
plot_rsa({'group'},'noise_ws_time-movingWin_chan-all_.*')
saveallfigures('png','noise_ws_timemavg')
close all
plot_rsa({'group'},'noise_sum_time-resolved_chan-all_.*')
saveallfigures('png','noise_sum_timeres')
close all
plot_rsa({'group'},'noise_sum_time-movingWin_chan-all_.*')
saveallfigures('png','noise_sum_timemavg')
close all
plot_rsa({'group'},'words_time-resolved_chan-all_.*')
saveallfigures('png','words_timeres')
close all
plot_rsa({'group'},'words_time-movingWin_chan-all_.*')
saveallfigures('png','words_timemavg')
close all