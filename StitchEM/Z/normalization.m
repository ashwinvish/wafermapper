N = 2;
K = 1000;
M1 = 10000;
M2 = 2*M1;
m  = [-3; 6];
s  = [1.5; 2.5];
x1 = s(1)*randn(M1,1) + m(1);
x2 = s(2)*randn(M2,1) + m(2);
x  = [x1; x2];

x = single(im1(:));

xaxis = [min(x):range(x)/(K-1):max(x)]';
xpdf  = hist(x,K)/length(x);

figure
plot(xaxis, xpdf, 'k');
xlabel('x');
ylabel('f(x)');

%%
% pre-allocation
mu     = zeros(N,1);
sigma  = zeros(N,1);
weight = zeros(N,1);
gaussPdfi = zeros(K,N);
gaussPdf  = zeros(K,1);
 
% fit
options = statset('Display','final');
obj = gmdistribution.fit(x,N,'Options',options);
gaussPdf = pdf(obj,xaxis);
A = sum(gaussPdf);
gaussPdf = gaussPdf/A;
 
% separating N Gaussians
for n = 1:N,
    mu(n)          = obj.mu(n);
    sigma(n)       = sqrt(obj.Sigma(1,1,n));
    weight(n)      = obj.PComponents(n);
    gaussPdfi(:,n) = weight(n)*normpdf(xaxis,mu(n),sigma(n))/A;
end

hold on
plot(xaxis, gaussPdf, 'r', 'linewidth', 1.25);
xlabel('x');
ylabel('f(x), F(x)');
hold off;
 
figure
area(xaxis, gaussPdfi(:,1));
h = findobj(gca, 'Type', 'patch');
set(h, 'FaceColor', 'g', 'EdgeColor', 'g', 'facealpha', 0.75);
hold on;
area(xaxis, gaussPdfi(:,2));
h = findobj(gca, 'Type', 'patch');
set(h,'facealpha', 0.75);
plot(xaxis, gaussPdf, 'r', 'linewidth', 1.25);
xlabel('x');
ylabel('F(x), f(x_1), f(x_2)');
hold off;
