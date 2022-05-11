(
~stats = ["mean","stddev","skew","kurt","min","median","max"];
~numDerivs = 1;
{"|:---:".post} ! ((~numDerivs+1) * ~stats.size);
"|".postln;
3.do{
	arg chan;
	"| ".post;
	(~numDerivs+1).do{
		arg deriv;
		if(deriv == 0,{deriv = ""},{deriv = "deriv % ".format(deriv)});
		~stats.do{
			arg stat;
			"%% | ".format(deriv,stat).post;
		}
	};
	"".postln;
};
)