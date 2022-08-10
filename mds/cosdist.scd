(
~norm = {
	arg val;
	val.pow(2).sum.sqrt;
};
~dot = {
	arg x_, y_;
	(x_ * y_).sum;
};
~cosdist = {
	arg x_, y_;
	var norm = ~norm.(x_) * ~norm.(y_);
	var dot = ~dot.(x_,y_);
	1-(dot / norm);
};
~cosdist.([100,100],[1,1]);
// ~win = Window(bounds:Rect(0,0,100,100));
)