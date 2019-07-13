vocode( '80','n','greenwood','half',320,6,'sent.wav', 'csn320.wav')
vocode( '80','i','greenwood','half',320,6,'sent.wav', 'csi320.wav')
vocode( '80','n','greenwood','half', 30,6,'sent.wav', 'csn30.wav')
vocode( '80','i','greenwood','half', 30,6,'sent.wav', 'csi30.wav')
vocode('-80','n','greenwood','half',320,6,'sent.wav', 'can320.wav')
vocode('-80','i','greenwood','half',320,6,'sent.wav', 'cai320.wav')
vocode('-80','n','greenwood','half', 30,6,'sent.wav', 'can30.wav')
vocode('-80','i','greenwood','half', 30,6,'sent.wav', 'cai30.wav')

%or:

f0s='70 80 90 200 220 240';
vocode(f0s,'n','greenwood','half', 30,6,'sent.wav', 'dsn30.wav')
f0s='-70 -80 -90 -200 -220 -240';
vocode(f0s,'n','greenwood','half', 30,6,'sent.wav', 'dan30.wav')
f0s='-70 80 -90 200 -220 240';
vocode(f0s,'n','greenwood','half', 30,6,'sent.wav', 'dmn30.wav')
