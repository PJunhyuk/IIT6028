function I_HDR_tm = photo_tonemap(K, B, I_HDR)

[height, width, ch] = size(I_HDR);

I_HDR_norm = zeros(height, width, ch);
for i = 1: ch
    I_HDR_norm(:,:,i) = I_HDR(:,:,i) * K / exp(mean(mean(log(I_HDR(:,:,i) + 1e-10))));
end

I_white = B * max(max(I_HDR_norm));

I_HDR_tm = I_HDR_norm .* (1 + I_HDR_norm ./ (I_white.*I_white) ./ (1+I_HDR_norm));

end