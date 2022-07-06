%Bandpass Filter on data
[y, Fs]= audioread('record.wav');
Fn = Fs/2;                              % Nyquist Frequency
fc1 = 1200/Fn;                           % Normalised Frequency
fc2 = 6000/Fn;                          % Normalised Frequency
% B= fir1(31, [fc1 fc2], 'bandpass');
% %this is a hamming window
% [H1, om1]=freqz(B);        %raspunsul in frecventa
% figure(1)
% fc1= [  0.159534 0.779262];
% fc2= [  0.5232  0.522845];
% labels= {'fc1', 'fc2'};
% plot(om1, abs(H1));
% hold on
% plot(fc1, fc2, 'o')
% title('Filtru Trece Banda');
% xlabel('Pulsatie') 
% ylabel('Amplitudine') 
% text(fc1, fc2, labels, 'VerticalAlignment','bottom', 'HorizontalAlignment', 'right')
% hold off


beta=3;
win= kaiser(32, beta);
B= fir1(31, [fc1 fc2], 'bandpass', win);

% [H1, om1]=freqz(B);        %raspunsul in frecventa
% figure(1)
% fc1= [  0.159534 0.779262];
% fc2= [  0.5232  0.522845];
% labels= {'fc1', 'fc2'};
% plot(om1, abs(H1));
% % hold on
% plot(fc1, fc2, 'o')
% title('Filtru Trece Banda');
% xlabel('Pulsatie') 
% ylabel('Amplitudine') 
% text(fc1, fc2, labels, 'VerticalAlignment','bottom', 'HorizontalAlignment', 'right')
% hold off

y_Filtered= filtfilt(B, 1, y);
figure(2)
plot(y_Filtered)

audiowrite('Matlab-bandpass-withKaiser.wav',y_Filtered,Fs);