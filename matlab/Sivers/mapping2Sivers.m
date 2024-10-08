function w_mapped = mapping2Sivers(array,x,y,w)

w_mapped = zeros(32,size(w,2));
w_mapped(1,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(1))) == 1,:); % V15
w_mapped(2,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(2))) == 1,:); % V14
w_mapped(3,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(1))) == 1,:); % V13
w_mapped(4,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(2))) == 1,:); % V12
w_mapped(5,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(3))) == 1,:); % V11
w_mapped(6,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(4))) == 1,:); % V10
w_mapped(7,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(3))) == 1,:); % V9
w_mapped(8,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(4))) == 1,:); % V8
w_mapped(9,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(1))) == 1,:); % V7
w_mapped(10,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(2))) == 1,:); % V6
w_mapped(11,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(1))) == 1,:); % V5
w_mapped(12,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(2))) == 1,:); % V4
w_mapped(13,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(3))) == 1,:); % V3
w_mapped(14,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(4))) == 1,:); % V2
w_mapped(15,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(3))) == 1,:); % V1
w_mapped(16,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(4))) == 1,:); % V0


w_mapped(17,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(1))) == 1,:); % H15
w_mapped(18,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(1))) == 1,:); % H14
w_mapped(19,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(2))) == 1,:); % H13
w_mapped(20,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(2))) == 1,:); % H12
w_mapped(21,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(3))) == 1,:); % H11
w_mapped(22,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(3))) == 1,:); % H10
w_mapped(23,:) = w(((array(1,:) == x(4)) .* (array(2,:) == y(4))) == 1,:); % H9
w_mapped(24,:) = w(((array(1,:) == x(3)) .* (array(2,:) == y(4))) == 1,:); % H8
w_mapped(25,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(1))) == 1,:); % H7
w_mapped(26,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(1))) == 1,:); % H6
w_mapped(27,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(2))) == 1,:); % H5
w_mapped(28,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(2))) == 1,:); % H4
w_mapped(29,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(3))) == 1,:); % H3
w_mapped(30,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(3))) == 1,:); % H2
w_mapped(31,:) = w(((array(1,:) == x(1)) .* (array(2,:) == y(4))) == 1,:); % H1
w_mapped(32,:) = w(((array(1,:) == x(2)) .* (array(2,:) == y(4))) == 1,:); % H0
end