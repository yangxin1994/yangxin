#!/bin/bash  
#

array=(faq public_notice feedback)
echo "################ Start Test #############"
for x in "${array[@]}"; do 
  ruby -Itest /home/com/Quill/test/unit/"$x"_test.rb
  ruby -Itest /home/com/Quill/test/functional/"$x"s_controller_test.rb 
done
echo "############### END #########################"
