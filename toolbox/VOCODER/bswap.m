
 function c=bswap(a)

 b=fix(a/256);
 a=rem(a,256);
 c=a*256+b;
