function dist = pointToSegmentDistance(X, Y, A, B)
    AB = B - A;
    denom = AB(1)^2 + AB(2)^2;

    if denom < 1e-12
        dist = hypot(X - A(1), Y - A(2));
        return;
    end

    t = ((X - A(1)).*AB(1) + (Y - A(2)).*AB(2)) / denom;
    t = min(max(t, 0), 1);

    projX = A(1) + t .* AB(1);
    projY = A(2) + t .* AB(2);
    dist = hypot(X - projX, Y - projY);
end
