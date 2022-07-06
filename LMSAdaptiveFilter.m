%Filtru Adaptiv cu MCMMP

[signal1, Fs]= audioread('record.wav');
[noise1, Fsn]= audioread('justNoise.wav');
signal=signal1(:, 1)*10;
noise= noise1(:, 1)*10;


% Parametrii filtrului Adaptiv
step_size= 5;
filterLength = 28;

% initializarea parametrilor cu care vom lucra
weights = zeros(filterLength, 1);
output = zeros(1,length(signal));
err = zeros(1,length(signal));
input = zeros(1,filterLength);

% Bucla functionala
for n = filterLength: length(signal)
      input = noise(n:-1:n-filterLength+1);  
      output(n) = weights' * input;  %Iesirea filtrului
      err(n)  = signal(n) - output(n); %eroarea
      weights = weights + step_size * err(n) * input; %ponderile 
end

yClean = err/10;

audiowrite('AdaptiveFilterExp.wav',yClean,Fs);