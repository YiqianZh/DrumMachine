function out = f_bdwg( freqs, B, decay, Tsamp, fs, low_high, damp )
% Banded digital waveguide function

%% variables

noPlot = 1;

n_modes = length(freqs); % number of modes
d = zeros(1, n_modes); % length of delay lines (Samples)
for i = 1:n_modes
    d(i) = floor(fs/freqs(i));
end

%% initialization

L = rand(1, max(d)); % initialize delay lines with white noise
L = L - mean(L);
L = L/max(L);
L = repmat(L,n_modes,1);

out = zeros(1, Tsamp); % output

p_out = 3*ones(1,n_modes); % pointers out      (see shift register)
p_out1 = 2*ones(1,n_modes);
p_out2 = 1*ones(1,n_modes);

p_in = 6*ones(1,n_modes); % pointers in
p_in1 = 5*ones(1,n_modes);
p_in2 = 4*ones(1,n_modes);
%p_in3 = 4*ones(1,n_modes);

%% bandpass filter coefficients around fundamental using butter()

% w_low = 0.6; % 75% below f0
% w_high = 1.4; % 125% upper f0
% a = zeros(n_modes, 3);
% b = zeros(n_modes, 3);
% for i = 1:n_modes
%     [b(i,:),a(i,:)] = butter(1, [w_low w_high]*(freqs(i)/fs*2), 'bandpass'); % (unit of cutoff frequencies in "pi rad/sample")
% end

%% bandpass according to paper (following Steiglitz's DSP book, 1996)

f_low_high = low_high*freqs;
B = f_low_high(2,:) - f_low_high(1,:); % bandwidth
%B = B';
B_rad = 2*pi/fs .* B; % bandwidth in radians/samp
psi = 2*pi/fs * freqs; % center frequencies in radians/samp
R = 1 - B_rad/2;
cosT = 2*R/(1+R.^2) * cos(psi);
A0 = (1-R.^2)/2; % normalization scale factor or gain adjustement
% A0 = sqrt(A0);


% a and b coefficients
a = zeros(n_modes, 3);
b = zeros(n_modes, 3);
for i = 1:n_modes
    b(i,:) = [A0(i), 0, -A0(i)]; % b coeff dependent of scaling gain factor
    a(i,:) = [1, -2*R(i)*cosT(i), R(i)^2]; % a coeff depending on R and cosT     
end

% a = zeros(n_modes, 3);
% b = zeros(n_modes, 4);
% for i = 1:n_modes
%     u = 2*R(i)*cosT(i);
%     v = R(i)^2;
%     b(i,:) = A0(i)*[1, -damp, -1, damp];
%     a(i,:) = [1, -(damp+u-u*damp), v*(1-damp)];
% end


%% main loop

for i=1:Tsamp
    
    out(i) = 0;
    
    for j = 1:n_modes
        
        % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
        L(j, p_out(j)) = decay(j) * (b(j,1)*L(j, p_in(j)) + ...                               % b(j,2)*L(j, p_in1(j))... (=0)
            + b(j,3)*L(j, p_in2(j)) - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)));
        
        % bandpass and lowpass
%         L(j, p_out(j)) = b(j,1)*L(j, p_in(j)) + b(j,2)*L(j, p_in1(j)) + b(j,3)*L(j, p_in2(j)) + b(j,4)*L(j, p_in3(j))...
%              - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j));
        
        out(i) = out(i) + L(j,p_out(j));
        
        % update and wrap pointers
        if (p_in(j)==d(j))
            p_in(j)=1;
        else
            p_in(j)=p_in(j)+1;
        end
        if (p_in1(j)==d(j))
            p_in1(j)=1;
        else
            p_in1(j)=p_in1(j)+1;
        end
        if (p_in2(j)==d(j))
            p_in2(j)=1;
        else
            p_in2(j)=p_in2(j)+1;
        end
%         if (p_in3(j)==d(j))
%             p_in3(j)=1;
%         else
%             p_in3(j)=p_in3(j)+1;
%         end
        if (p_out(j)==d(j))
            p_out(j)=1;
        else
            p_out(j)=p_out(j)+1;
        end
        if (p_out1(j)==d(j))
            p_out1(j)=1;
        else
            p_out1(j)=p_out1(j)+1;
        end
        if (p_out2(j)==d(j))
            p_out2(j)=1;
        else
            p_out2(j)=p_out2(j)+1;
        end
        
    end
end

%% sound and plots

% soundsc(out, fs)

if noPlot == 0
    % audio wave
    figure
    plot(out/max(out))
    
    % audio spectrum
    % Spec(out, fs) % my spectrum function
    
    % bandpass frequency response
    figure
    for i = 1:n_modes
        freqz(b(i,:),a(i,:)); hold on % magnitude and phase response
    end
    % % freqz colors
    % lines = findall(gcf,'type','line');
    % set(lines(1),'color','red')
    % set(lines(2),'color','green')
    % set(lines(3),'color','blue')
end


end

