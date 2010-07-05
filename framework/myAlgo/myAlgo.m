function myAlgo(root, db)
    classifier = SVM({GrowingTree}, {Intersection});
    
    evaluate(classifier, root, db, 'myAlgo/test');
end