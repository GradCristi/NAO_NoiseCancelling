%Incarcarea datelor si masurarea lungimii inregistrarii in esantioane
[y,Fe]=audioread('record.wav');
x=y(1:end,1).';  %remove the beginning of the sample
Nx=length(x);
fprintf('Audioread s-a executat cu succes');

%Parametrii algoritmului
apriori_SNR=1;  %A se selecta 0 pentru estimare aposteriori a SNR, 1 pentru apriori (see [2])
alpha=0.05;      %only used if apriori_SNR=1
beta1=0.5;
beta2=1;
lambda=3;

%parametrii STFT
NFFT=2048;   %numarul de puncte in care se face calculul TF discrete
window_length=round(0.031*Fe); %lungimea ferestrei, are un mare impact asupra roboticitatii vocii, tried to match it
window=kaiser(window_length, 3);
window = window(:);
overlap=floor(0.3*window_length); %numarul de ferestre folosite fara overlap, are impact asupra amplitudinii semnalului, matched it to the input

%Parametrii semnalului ce va fi folosit pentru zgomot
t_min=0.01;    % [t_min t_max] intervalul in care se va izola zgomotul
t_max=0.5;

%constructia spectogramelor
[S,F,T] = spectrogram(x+1i*eps,window,window_length-overlap,NFFT,Fe); %s-a adaugat un 1i*eps pentru a adauga o foarte mica parte imaginara si pt a obtine o spectograma cu doua parti(?)
[Nf,Nw]=size(S);

%S= contine o estimare de termen scurt a lui X
%F= vector de frecvente iar T este un vector de timp, ambele specifica
%momentele in care spectograma este calculata


%Extragerea spectrului zgomotului
t_index=find(T>t_min & T<t_max);  %indexii de timp in care T este cuprins intre cele doua intervale, specifica cat din spectograma este zgomotul de la inceput
absS_vuvuzela=abs(S(:,t_index)).^2; 
vuvuzela_spectrum=mean(absS_vuvuzela,2); %spectrul vuvuzelei mediu
vuvuzela_specgram=repmat(vuvuzela_spectrum,1,Nw);
fprintf('Zgomotul s-a izolat cu succes');

%Calcularea SNR
absS=abs(S).^2;
SNR_est=max((absS./vuvuzela_specgram)-1,0); % a posteriori SNR = Semnal supra zgomot totusi
if apriori_SNR==1
    SNR_est=filter((1-alpha),[1 -alpha],SNR_est);  %a priori SNR: [2] eq 53
end    

%---------------------------%
%  Compute attenuation map  %
%---------------------------%
fprintf('-> Step 4/5: Compute TF attenuation map -');
an_lk=max((1-lambda*((1./(SNR_est+1)).^beta1)).^beta2,0);
STFT=an_lk.*S;
fprintf(' OK\n');

%--------------------------%
%   Compute Inverse STFT   %
%--------------------------%
fprintf('-> Step 5/5: Compute Inverse STFT:');
ind=mod((1:window_length)-1,Nf)+1;
output_signal=zeros((Nw-1)*overlap+window_length,1);

for indice=1:Nw %Overlapp add technique
    left_index=((indice-1)*overlap) ;
    index=left_index+[1:window_length];
    temp_ifft=real(ifft(STFT(:,indice),NFFT));
    output_signal(index)= output_signal(index)+temp_ifft(ind).*window;
end
fprintf(' OK\n');


%-----------------    Display Figure   ------------------------------------      

%show temporal signals
figure
subplot(2,1,1);
t_index=find(T>t_min & T<t_max);
plot([1:length(x)]/Fe,x);
xlabel('Time (s)');
ylabel('Amplitude');
hold on;
noise_interval=floor([T(t_index(1))*Fe:T(t_index(end))*Fe]);
plot(noise_interval/Fe,x(noise_interval),'r');
hold off;
legend('Original signal','Noise Only');
title('Original Sound');
%show denoised signal
subplot(2,1,2);
plot([1:length(output_signal)]/Fe,output_signal );
xlabel('Time (s)');
ylabel('Amplitude');
title('Sound without noise');

%show spectrogram
t_epsilon=0.001;
figure
S_one_sided=max(S(1:length(F)/2,:),t_epsilon); %keep only the positive frequency
pcolor(T,F(1:end/2),10*log10(abs(S_one_sided))); 
shading interp;
colormap('hot');
title('Spectrogram: speech + noise');
xlabel('Time (s)');
ylabel('Frequency (Hz)');

figure
S_one_sided=max(STFT(1:length(F)/2,:),t_epsilon); %keep only the positive frequency
pcolor(T,F(1:end/2),10*log10(abs(S_one_sided))); 
shading interp;
colormap('hot');
title('Spectrogram: speech only');
xlabel('Time (s)');
ylabel('Frequency (Hz)');



%-----------------    Listen results   ------------------------------------


fprintf('OK\n');
fprintf('Write anti_vuvuzela.wa:');
audiowrite('anti_vuvuzela.wav', output_signal,Fe);
fprintf('OK\n');
