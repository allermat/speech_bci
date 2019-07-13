clear all
nbands = 16;

for b=1:nbands
    [lower,center,upper]= greenwud(b, 70, 5000, 0);
    tmp = [];
    for c=1:length(center)
        %Q = (upper(c)-lower(c))/center(c);
        %tmp = [tmp sprintf('%d %d %f %f,',c-1,1,center(c),Q)];
        tmp = [tmp sprintf('%d %d %f,',c-1,1,center(c))];
    end
    for c=length(center)+1:nbands
        %tmp = [tmp sprintf('%d %d %f %f,',c-1,0,10,10)];
        tmp = [tmp sprintf('%d %d %f,',c-1,0,10)];
    end
    tmp(end) = [];
    list{b,1} = tmp;
end