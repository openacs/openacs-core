<html>
<head>
<title>Recursive include</title>
</head>
  <body>
    <h2>
      Testcase for recursive <code>include</code> and <code>if</code>
    </h2>
    <p>
      This pages does two things:
    </p>
    <ol>
      <li>It exercises <code>include</code> recursively, passing
        changing args.
      <li>The result is the test case for <code>if</code> and
        <code>else</code>,  nesting them deeply and exercising all
        predicates, with and without "not"
    </ol>

    <p>
     <multiple name=v>
      <if @x@ not nil>
       <if @x@ nil>
         fail '@<%%>x@ nil' should be false
       </if><else>
        <if @y@ nil>
         <if @y@ not nil>
           fail '@<%%>y@ not nil' should be false
         </if><else>
          <if @z@ nil>
           <if @z@ not nil>
             fail '@<%%>z@ not nil' should be false
           </if><else>
            <if @x@ defined>
             <if @x@ not defined>
               fail '@<%%>x@ not defined' should be false
             </if><else>
              <if @y@ defined>
               <if @y@ not defined>
                 fail '@<%%>y@ not defined' should be false
               </if><else>
                <if @z@ not defined>
                 <if @z@ defined>
                   fail '@<%%>z@ defined' should be false
                 </if><else>
                  <if @x@ not lt 3>
                   <if @x@ lt 3>
                     fail '@<%%>x@ lt 3' should be false
                   </if><else>
                    <if "yes" true>
                     <if "yes" not true>
                       fail '"yes" not true' should be false
                     </if><else>
                      <if 0 not true>
                       <if 0 true>
                         fail '0 true' should be false
                       </if><else>
                        <if t not false>
                         <if t false>
                           fail 't false' should be false
                         </if><else>
                          <if oFf false>
                           <if oFf not false>
                             fail 'oFf not false' should be false
                           </if><else>
                            <if @x@ true>
                             <if @x@ not true>
                               fail '@<%%>x@ not true' should be false
                             </if><else>
                              <if @x@ gt @v.five@>
                               <if @x@ not gt @v.five@>
                                 fail '@<%%>x@ not gt @<%%>v.five@' should be false
                               </if><else>
                                <if @x@ not ge 20>
                                 <if @x@ ge 20>
                                   fail '@<%%>x@ ge 20' should be false
                                 </if><else>
                                  <if @x@ le 13>
                                   <if @x@ not le 13>
                                     fail '@<%%>x@ not le 13' should be false
                                   </if><else>
                                    <if @v.five@ eq 5>
                                     <if @v.five@ not eq 5>
                                       fail '@<%%>v.five@ not eq 5' should be false
                                     </if><else>
                                      <if @x@ not eq 5>
                                       <if @x@ eq 5>
                                         fail '@<%%>x@ eq 5' should be false
                                       </if><else>
                                        <if @x@ not odd>
                                         <if @x@ odd>
                                           fail '@<%%>x@ odd' should be false
                                         </if><else>
                                          <if @x@ even>
                                           <if @x@ not even>
                                             fail '@<%%>x@ not even' should be false
                                           </if><else>
                                            <if @v.rownum@ odd>
                                             <if @v.rownum@ not odd>
                                               fail '@<%%>v.rownum@ not odd' should be false
                                             </if><else>
                                              <if @v.five@ not even>
                                               <if @v.five@ even>
                                                 fail '@<%%>v.five@ even' should be false
                                               </if><else>
                                                <if @x@ not in fo {ob 10} ar>
                                                 <if @x@ in fo {ob 10} ar>
                                                   fail '@<%%>x@ in fo {ob 10} ar' should be false
                                                 </if><else>
                                                  <if @x@ in fie 6 10 28>
                                                   <if @x@ not in fie 6 10 28>
                                                     fail '@<%%>x@ not in fie 6 10 28' should be false
                                                   </if><else>
                                                    <if @v.five@ between 3 30>
                                                     <if @v.five@ not between 3 30>
                                                       fail '@<%%>v.five@ not between 3 30' should be false
                                                     </if><else>
                                                      <if @v.five@ not between 30 300>
                                                       <if @v.five@ between 30 300>
                                                         fail '@<%%>v.five@ between 30 300' should be false
                                                       </if><else>
                                                        <if @x@ ne @v.five@ and 8 not le @v.five@ and @x@ defined>
                                                         <if @x@ not ne @v.five@ or 8 le @v.five@ or @x@ not defined>
                                                           fail '@<%%>x@ not ne @<%%>v.five@ or 8 le @<%%>v.five@ or @<%%>x@ not defined' should be false
                                                         </if><else>
                                                          <if @x@ ne 10 or 6 not eq @v.five@>
                                                           <if @x@ not ne 10 and 6 eq @v.five@>
                                                             fail '@<%%>x@ not ne 10 and 6 eq @<%%>v.five@' should be false
                                                           </if><else>
                                                             pass the test.                                                           </else>
                                                          </if><else>
                                                           fail '@<%%>x@ ne 10 or 6 not eq @<%%>v.five@' should be true
                                                          </else>
                                                         </else>
                                                        </if><else>
                                                         fail '@<%%>x@ ne @<%%>v.five@ and 8 not le @<%%>v.five@ and @<%%>x@ defined' should be true
                                                        </else>
                                                       </else>
                                                      </if><else>
                                                       fail '@<%%>v.five@ not between 30 300' should be true
                                                      </else>
                                                     </else>
                                                    </if><else>
                                                     fail '@<%%>v.five@ between 3 30' should be true
                                                    </else>
                                                   </else>
                                                  </if><else>
                                                   fail '@<%%>x@ in fie 6 10 28' should be true
                                                  </else>
                                                 </else>
                                                </if><else>
                                                 fail '@<%%>x@ not in fo {ob 10} ar' should be true
                                                </else>
                                               </else>
                                              </if><else>
                                               fail '@<%%>v.five@ not even' should be true
                                              </else>
                                             </else>
                                            </if><else>
                                             fail '@<%%>v.rownum@ odd' should be true
                                            </else>
                                           </else>
                                          </if><else>
                                           fail '@<%%>x@ even' should be true
                                          </else>
                                         </else>
                                        </if><else>
                                         fail '@<%%>x@ not odd' should be true
                                        </else>
                                       </else>
                                      </if><else>
                                       fail '@<%%>x@ not eq 5' should be true
                                      </else>
                                     </else>
                                    </if><else>
                                     fail '@<%%>v.five@ eq 5' should be true
                                    </else>
                                   </else>
                                  </if><else>
                                   fail '@<%%>x@ le 13' should be true
                                  </else>
                                 </else>
                                </if><else>
                                 fail '@<%%>x@ not ge 20' should be true
                                </else>
                               </else>
                              </if><else>
                               fail '@<%%>x@ gt @<%%>v.five@' should be true
                              </else>
                             </else>
                            </if><else>
                             fail '@<%%>x@ true' should be true
                            </else>
                           </else>
                          </if><else>
                           fail 'oFf false' should be true
                          </else>
                         </else>
                        </if><else>
                         fail 't not false' should be true
                        </else>
                       </else>
                      </if><else>
                       fail '0 not true' should be true
                      </else>
                     </else>
                    </if><else>
                     fail '"yes" true' should be true
                    </else>
                   </else>
                  </if><else>
                   fail '@<%%>x@ not lt 3' should be true
                  </else>
                 </else>
                </if><else>
                 fail '@<%%>z@ not defined' should be true
                </else>
               </else>
              </if><else>
               fail '@<%%>y@ defined' should be true
              </else>
             </else>
            </if><else>
             fail '@<%%>x@ defined' should be true
            </else>
           </else>
          </if><else>
           fail '@<%%>z@ nil' should be true
          </else>
         </else>
        </if><else>
         fail '@<%%>y@ nil' should be true
        </else>
       </else>
      </if><else>
       fail '@<%%>x@ not nil' should be true
      </else>

     </multiple>
    </p>
  </body>
</html>
