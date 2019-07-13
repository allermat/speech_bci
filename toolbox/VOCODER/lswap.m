
 function e=lswap(a)

 for k=(1:4), if (a(k)<0) a(k)=256+a(k); end, end
 e=256*256*(a(3)+256*a(4))+(a(1)+256*a(2));
