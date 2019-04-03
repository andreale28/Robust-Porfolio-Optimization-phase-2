clc;
clear all;

% Read the csv file (Change it to "final_list100.csv" for BSE100)
table = readtable('./data_related/final_list30.csv');
% table = readtable('./data_related/final_list100.csv');

stock_prices = table{:,2:end};
stock_prices = diff(log(stock_prices));
mu = mean(stock_prices);
mu = mu';
covariance = cov(stock_prices);


% Jarque Bera Test
% 
% cnt = 0;
% for i = 1:size(stock_prices,2)
%     ks_vec=stock_prices(:,i);
%     m_ks=mean(ks_vec);
%     sig_ks=std(ks_vec);
%     ks_vec=ks_vec-m_ks;
%     ks_vec=ks_vec/sig_ks;
%     [h,p] = jbtest(ks_vec);
%     if (h==1)
%         cnt = cnt+1;
%     end
%     
% end
% disp(cnt)
% return;


% Uncomment if needed to use the simulated data

% rng default  % For reproducibility
% %m=1000;   % If #simulations is 1000
% m=size(stock_prices,1); % If #simulations is same as market data
% temp_data = mvnrnd(mu,covariance,m);
% stock_prices=temp_data;
% mu = mean(stock_prices);
% mu = mu';
% covariance = cov(stock_prices);


e_range  = 0.001:5*10^(-3):0.1;
% e_range = 0.0001:10^(-4):0.01

mean_vals_base = zeros(size(e_range,2),1);
sd_vals_base = zeros(size(e_range,2),1);

N = size(stock_prices,2);
S = size(stock_prices,1);

init = rand(N+S+2,1);

for i=1:size(e_range,2)
    
    e = e_range(1,i);
    
%     Constraints in Obj function.
    
    
%     init=rand(N+1,1);
%     A_f=[stock_prices,ones(S,1)];
%     min_obj_f=@(y)(y(N+1)+(1/(S*e))*sum(max(A_f*y,zeros(S,1))) );
%     A=(-1)*[eye(N),zeros(N,1)];
%     b=zeros(N,1);
%     A_eq=[ones(1,N),0];
%     b_eq=1;
    
    
    
    options = optimoptions(@fmincon,'Algorithm','interior-point','MaxIterations',6000);
    options.MaxFunctionEvaluations = 80000;
%     options.StepTolerance = 10^(-16);
    
    min_obj_f = @(y) (y(N+S+2));
%     min_obj_f = zeros(N+S+2,1);
%     min_obj_f(end)=1;
    
    A=zeros(N+2*S+1,N+S+2);
    b=zeros(N+2*S+1,1);
    
    A(1:N,1:N)=(-1)*eye(N);
    A(N+1,N+1)=1;
    A(N+1,N+S+2)=-1;
    A(N+1,(N+2):(N+S+1))=(1/(S*e))*ones(1,S);
    A((N+2):(N+S+1),N+1)=(-1)*ones(S,1);
    A((N+2):(N+S+1),(N+2):(N+S+1))=(-1)*eye(S);
    A((N+2):(N+S+1),1:N)=(-1)*stock_prices;
    A((N+S+2):(N+2*S+1),(N+2):(N+S+1))=(-1)*eye(S);
    
    A_eq=zeros(1,N+S+2);
    A_eq(1,1:N)=ones(1,N);
    b_eq=1;
%     options = optimoptions('linprog','Algorithm','interior-point-legacy');
    
    [y,fval,exitflag,output] = fmincon(min_obj_f,init,A,b,A_eq,b_eq,[],[],[],options);
    x=y(1:N);
    mean_vals_base(i) = mu'*x;
    sd_vals_base(i) = sqrt(x'*covariance*x);
    
end




mark_size = 5;

% Efficient Frontier

% F=figure(1); hold on;
% box on
% grid on
% plot(sd_vals_base, mean_vals_base,'-s','markers',mark_size);
% %plot(sd_vals_wvar, mean_vals_wvar,'-o','markers',mark_size);
% lgd = legend('Base CVaR');
% lgd.Location = 'southeast';
% ylabel('Return');
% xlabel('Standard Deviation')
% saveas(F,'ef_30_cvar_cons.jpeg');
% %saveas(F,'./JPEGs/bse30_simulated/ef_exact_cheb.jpeg');
% %saveas(F,'./EPSs/bse30_simulated/ef_exact_cheb.eps','epsc');
% 
% hold off






% Robust Models

sample_prob = mvnpdf(stock_prices, mu', covariance);
sample_prob = sample_prob./(sum(sample_prob));


upper_eta = max(0, sample_prob - 1/S);
lower_eta = max(0, 1/S - sample_prob);

rho = norm(sample_prob - 1/S);
scale = rho*eye(S);

mean_vals_wcvar = zeros(size(e_range,2),1);
sd_vals_wcvar = zeros(size(e_range,2),1);

init = rand(N+3*S+3,1);
% Box Uncertainty

for i=1:size(e_range,2)
    
    e = e_range(1,i)
    
%     Constraints in Obj function.
    
    
%     init=rand(N+1,1);
%     A_f=[stock_prices,ones(S,1)];
%     min_obj_f=@(y)(y(N+1)+(1/(S*e))*sum(max(A_f*y,zeros(S,1))) );
%     A=(-1)*[eye(N),zeros(N,1)];
%     b=zeros(N,1);
%     A_eq=[ones(1,N),0];
%     b_eq=1;
    
    
    
    options = optimoptions(@fmincon,'Algorithm','interior-point','MaxIterations',6000);
    options.MaxFunctionEvaluations = 8000;
%     options.StepTolerance = 10^(-16);
    
    min_obj_f = @(y) (y(N+3*S+3));
    
%     min_obj_f = zeros(N+3*S+3,1);
%     min_obj_f(end)=1;
    
    A=zeros(N+4*S+1,N+3*S+3);
    b=zeros(N+4*S+1,1);
    
    A(1:N,1:N)=(-1)*eye(N);
    
    A(N+1,N+1:N+S)=(1/(S*e)).*ones(1,S);
    A(N+1,N+S+2 : N+2*S+1)=(1/e)*upper_eta';
    A(N+1,N+2*S+2:N+3*S+1)=(1/e)*lower_eta';
    A(N+1,N+3*S+2)=1;
    A(N+1,N+3*S+3)=-1;
    
    A(N+2:N+S+1,N+S+2:N+2*S+1)= (-1)*eye(S);
    
    A(N+S+2:N+2*S+1,N+2*S+2:N+3*S+1)=eye(S);
    
    A(N+2*S+2 : N+3*S+1,N+3*S+2)=(-1)*ones(S,1);
    A(N+2*S+2 : N+3*S+1,N+1:N+S)= (-1)*eye(S);
    A(N+2*S+2 : N+3*S+1,1:N)= (-1)*stock_prices;
    
    A(N+3*S+2 : N+4*S+1, N+1:N+S)= (-1)*eye(S);
    
    
    A_eq=zeros(S+1,N+3*S+3);
    b_eq=zeros(S+1,1);
    
    A_eq(1:S,N+1+S)=ones(S,1);
    A_eq(1:S,N+1:N+S)=(-1)*eye(S);
    A_eq(1:S,N+S+2:N+2*S+1)=eye(S);
    A_eq(1:S,N+2*S+2:N+3*S+1)=eye(S);
    
    A_eq(S+1,1:N)=ones(1,N);
    b_eq(S+1,1)=1;
    
    
%     A=zeros(N+2*S+1,N+S+2);
%     b=zeros(N+2*S+1,1);
%     
%     A(1:N,1:N)=(-1)*eye(N);
%     A(N+1,N+1)=1;
%     A(N+1,N+S+2)=-1;
%     A(N+1,(N+2):(N+S+1))=(1/(S*e))*ones(1,S);
%     A((N+2):(N+S+1),N+1)=(-1)*ones(S,1);
%     A((N+2):(N+S+1),(N+2):(N+S+1))=(-1)*eye(S);
%     A((N+2):(N+S+1),1:N)=(-1)*stock_prices;
%     A((N+S+2):(N+2*S+1),(N+2):(N+S+1))=(-1)*eye(S);
%     
%     A_eq=zeros(1,N+S+2);
%     A_eq(1,1:N)=ones(1,N);
%     b_eq=1;
    
%     options = optimoptions('linprog','Algorithm','interior-point-legacy');
    [y,fval,exitflag,output] = fmincon(min_obj_f,init,A,b,A_eq,b_eq,[],[],[],options);
    x=y(1:N);
    mean_vals_wcvar(i) = mu'*x;
    sd_vals_wcvar(i) = sqrt(x'*covariance*x);
    
end


risk_free = log(1.06)/365;
base = (mean_vals_base - risk_free)./sd_vals_base;
wcvar = (mean_vals_wcvar - risk_free)./sd_vals_wcvar;


F = figure(2); hold on;
box on
grid on
plot(e_range, base,'-o');
plot(e_range, wcvar,'-s');
lgd = legend('Base CVaR','Worst CVar');
lgd.Location = 'southeast';
ylabel('Sharpe Ratio');
xlabel('\epsilon(Confidence level)');
saveas(F,'sr_30_cvar_cons.jpeg');

% change the names of the files and folders accordingly.
%saveas(F,'./JPEGs/bse30_simulated/sr_exact_cheb.jpeg');
%saveas(F,'./EPSs/bse30_simulated/sr_exact_cheb.eps','epsc');
hold off





